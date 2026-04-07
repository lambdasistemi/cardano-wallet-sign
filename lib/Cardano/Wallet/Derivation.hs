{- |
Module      : Cardano.Wallet.Derivation
Description : BIP39 mnemonic to Cardano wallet derivation
License     : Apache-2.0

Derives Ed25519 signing keys from BIP39 mnemonics
via CIP-1852 (BIP32-Ed25519, Icarus style).
Path: @m\/1852'\/1815'\/0'\/0\/0@
-}
module Cardano.Wallet.Derivation (
    -- * Wallet derivation
    walletFromMnemonic,
    WalletError (..),
) where

import Cardano.Address (bech32)
import Cardano.Address.Derivation (
    Depth (..),
    deriveAccountPrivateKey,
    deriveAddressPrivateKey,
    genMasterKeyFromMnemonic,
    pubToBytes,
    xpubToPub,
 )
import Cardano.Address.Style.Shelley (
    Credential (PaymentFromExtendedKey),
    Role (UTxOExternal),
    Shelley,
    getKey,
    mkNetworkDiscriminant,
    paymentAddress,
 )
import Cardano.Crypto.Hash (HashAlgorithm (..))
import Cardano.Crypto.Hash.Blake2b (Blake2b_224)
import Cardano.Crypto.Wallet (XPrv)
import Cardano.Crypto.Wallet qualified as HD
import Cardano.Mnemonic (
    MkSomeMnemonic (mkSomeMnemonic),
 )
import Cardano.Wallet.Sign (signTx)
import Cardano.Wallet.Types (
    Address (..),
    Owner (..),
    Wallet (..),
 )
import Data.Bifunctor (first)
import Data.ByteString.Base16 qualified as Base16
import Data.Proxy (Proxy (..))
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.Encoding qualified as T

-- | Wallet derivation errors.
newtype WalletError
    = InvalidMnemonic String
    deriving stock (Show, Eq)

{- | Derive a 'Wallet' from a BIP39 mnemonic.

Supports 9, 12, 15, 18, and 24 word mnemonics.
Uses testnet network discriminant (tag 0).
-}
walletFromMnemonic :: Text -> Either WalletError Wallet
walletFromMnemonic mnemonicText = do
    (xprv, xpub) <- deriveKeyPair mnemonicText
    let tag =
            either (error . show) id $
                mkNetworkDiscriminant 0
        addr =
            Address $
                bech32 $
                    paymentAddress tag $
                        PaymentFromExtendedKey xpub
        pubBytes =
            pubToBytes $ xpubToPub $ getKey xpub
        own =
            Owner $
                T.decodeUtf8 $
                    Base16.encode $
                        digest
                            (Proxy @Blake2b_224)
                            pubBytes
    pure
        Wallet
            { walletAddress = addr
            , walletOwner = own
            , walletSign = signTx $ getKey xprv
            }

-- | Derive the key pair from a mnemonic.
deriveKeyPair
    :: Text
    -> Either
        WalletError
        ( Shelley 'PaymentK XPrv
        , Shelley 'PaymentK HD.XPub
        )
deriveKeyPair mnemonicText = do
    mnemonic <-
        first (InvalidMnemonic . show) $
            mkSomeMnemonic @'[9, 12, 15, 18, 24] $
                T.words mnemonicText
    let rootXPrv :: Shelley 'RootK XPrv
        rootXPrv =
            genMasterKeyFromMnemonic mnemonic mempty
        accXPrv :: Shelley 'AccountK XPrv
        accXPrv =
            deriveAccountPrivateKey rootXPrv minBound
        addrXPrv :: Shelley 'PaymentK XPrv
        addrXPrv =
            deriveAddressPrivateKey
                accXPrv
                UTxOExternal
                minBound
        addrXPub = HD.toXPub <$> addrXPrv
    pure (addrXPrv, addrXPub)
