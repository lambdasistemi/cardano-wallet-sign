{-# LANGUAGE RecordWildCards #-}

{- |
Module      : Cardano.Wallet.Encrypt
Description : AES-256-GCM wallet file encryption
License     : Apache-2.0

Encrypt and decrypt wallet mnemonic files using
AES-256-GCM with PBKDF2-SHA256 key derivation.
-}
module Cardano.Wallet.Encrypt (
    -- * Encryption
    encryptMnemonic,
    decryptMnemonic,
    EncryptError (..),

    -- * Wallet file format
    WalletFile (..),
    readWalletFile,
    writeWalletFile,
) where

import Control.Applicative (optional)
import Crypto.Cipher.AES (AES256)
import Crypto.Cipher.Types (
    AEAD,
    AEADMode (AEAD_GCM),
    AuthTag (..),
    aeadDecrypt,
    aeadEncrypt,
    aeadFinalize,
    aeadInit,
    cipherInit,
 )
import Crypto.Error (
    CryptoFailable (..),
 )
import Crypto.KDF.PBKDF2 (
    Parameters (..),
    fastPBKDF2_SHA256,
 )
import Crypto.Random (getRandomBytes)
import Data.Aeson (
    FromJSON (..),
    ToJSON (..),
    object,
    withObject,
    (.:),
    (.=),
 )
import Data.Aeson qualified as Aeson
import Data.Aeson.Types (Parser)
import Data.ByteArray (convert)
import Data.ByteString (ByteString)
import Data.ByteString.Base16 qualified as Base16
import Data.ByteString.Lazy qualified as BL
import Data.Text (Text)
import Data.Text.Encoding qualified as T

-- | Wallet file: either plaintext or encrypted.
data WalletFile
    = Plaintext Text
    | Encrypted
        { encSalt :: ByteString
        -- ^ PBKDF2 salt (16 bytes)
        , encIv :: ByteString
        -- ^ GCM nonce (12 bytes)
        , encTag :: ByteString
        -- ^ GCM auth tag (16 bytes)
        , encPayload :: ByteString
        -- ^ encrypted mnemonic
        }
    deriving stock (Show, Eq)

instance ToJSON WalletFile where
    toJSON (Plaintext m) =
        object ["mnemonics" .= m]
    toJSON Encrypted{..} =
        object
            [ "encrypted"
                .= T.decodeUtf8
                    (Base16.encode encPayload)
            , "salt"
                .= T.decodeUtf8
                    (Base16.encode encSalt)
            , "iv"
                .= T.decodeUtf8
                    (Base16.encode encIv)
            , "tag"
                .= T.decodeUtf8
                    (Base16.encode encTag)
            ]

instance FromJSON WalletFile where
    parseJSON = withObject "WalletFile" $ \o -> do
        mMnemonics <- optional (o .: "mnemonics")
        case mMnemonics of
            Just m -> pure $ Plaintext m
            Nothing -> do
                encPayload <-
                    decodeHex =<< o .: "encrypted"
                encSalt <- decodeHex =<< o .: "salt"
                encIv <- decodeHex =<< o .: "iv"
                encTag <- decodeHex =<< o .: "tag"
                pure Encrypted{..}

decodeHex :: Text -> Parser ByteString
decodeHex t =
    case Base16.decode (T.encodeUtf8 t) of
        Left err -> fail $ "bad hex: " <> err
        Right bs -> pure bs

-- | Encryption errors.
data EncryptError
    = CipherError String
    | NotEncrypted
    | AuthenticationFailed
    deriving stock (Show, Eq)

-- | PBKDF2 parameters: 100k iterations, 32-byte key.
kdfParams :: Parameters
kdfParams =
    Parameters
        { iterCounts = 100_000
        , outputLength = 32
        }

{- | Encrypt a mnemonic with a passphrase.

Uses PBKDF2-SHA256 for key derivation and AES-256-GCM
for authenticated encryption.
-}
encryptMnemonic
    :: ByteString
    -- ^ passphrase
    -> Text
    -- ^ mnemonic
    -> IO WalletFile
encryptMnemonic passphrase mnemonic = do
    encSalt <- getRandomBytes 16
    encIv <- getRandomBytes 12
    let key :: ByteString
        key =
            fastPBKDF2_SHA256
                kdfParams
                passphrase
                encSalt
        plainBytes = T.encodeUtf8 mnemonic
    case initAead key encIv of
        Left err ->
            error $
                "encryptMnemonic: " <> show err
        Right aead -> do
            let (encPayload, aead') =
                    aeadEncrypt aead plainBytes
                AuthTag tagBa =
                    aeadFinalize aead' 16
                encTag = convert tagBa
            pure Encrypted{..}

{- | Decrypt an encrypted wallet file with a passphrase.

Returns the mnemonic text on success.
-}
decryptMnemonic
    :: ByteString
    -- ^ passphrase
    -> WalletFile
    -- ^ encrypted wallet
    -> Either EncryptError Text
decryptMnemonic _ (Plaintext m) = Right m
decryptMnemonic passphrase Encrypted{..} = do
    let key :: ByteString
        key =
            fastPBKDF2_SHA256
                kdfParams
                passphrase
                encSalt
    aead <- initAead key encIv
    let (plainBytes, aead') =
            aeadDecrypt aead encPayload
        AuthTag computedTag =
            aeadFinalize aead' 16
    if convert computedTag /= encTag
        then Left AuthenticationFailed
        else Right $ T.decodeUtf8 plainBytes

-- | Initialize an AES-256-GCM AEAD context.
initAead
    :: ByteString
    -> ByteString
    -> Either EncryptError (AEAD AES256)
initAead key iv =
    case cipherInit key of
        CryptoFailed err ->
            Left $ CipherError $ show err
        CryptoPassed cipher ->
            case aeadInit AEAD_GCM cipher iv of
                CryptoFailed err ->
                    Left $ CipherError $ show err
                CryptoPassed aead ->
                    Right aead

-- | Read a wallet file from disk.
readWalletFile :: FilePath -> IO WalletFile
readWalletFile path = do
    bs <- BL.readFile path
    case Aeson.decode bs of
        Nothing ->
            fail $ "Cannot parse wallet: " <> path
        Just wf -> pure wf

-- | Write a wallet file to disk.
writeWalletFile :: FilePath -> WalletFile -> IO ()
writeWalletFile path =
    BL.writeFile path . Aeson.encode
