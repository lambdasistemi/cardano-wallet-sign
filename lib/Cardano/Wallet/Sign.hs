{- |
Module      : Cardano.Wallet.Sign
Description : Conway-era transaction signing
License     : Apache-2.0

Sign Cardano Conway-era transactions with an
Ed25519 extended private key.
-}
module Cardano.Wallet.Sign (
    -- * Signing
    signTx,
    signLedgerTx,

    -- * Serialization
    serializeTx,
    deserializeTx,
) where

import Cardano.Crypto.DSIGN.Class qualified as Crypto
import Cardano.Crypto.Util qualified as Crypto
import Cardano.Crypto.Wallet (XPrv)
import Cardano.Crypto.Wallet qualified as HD
import Cardano.Ledger.Api (
    ConwayEra,
    EraTx (Tx),
    KeyRole (..),
    WitVKey (..),
    addrTxWitsL,
    eraProtVerLow,
    txIdTx,
    witsTxL,
 )
import Cardano.Ledger.Api qualified as L
import Cardano.Ledger.Api.Tx.In (TxId (..))
import Cardano.Ledger.Binary (
    DecCBOR (decCBOR),
    decodeFullAnnotator,
 )
import Cardano.Ledger.Binary.Encoding qualified as Ledger
import Cardano.Ledger.Core (extractHash)
import Cardano.Ledger.Keys (
    VKey (..),
    asWitness,
 )
import Cardano.Wallet.Types (
    SignTxError (..),
    SignedTx (..),
    UnsignedTx (..),
 )
import Control.Lens ((%~))
import Data.Bifunctor (first)
import Data.ByteString (ByteString)
import Data.ByteString.Base16 qualified as Base16
import Data.ByteString.Char8 qualified as BS
import Data.ByteString.Lazy qualified as BL
import Data.Function ((&))
import Data.Maybe (fromMaybe)
import Data.Set qualified as Set
import Data.Text.Encoding qualified as T

-- | Sign an unsigned transaction hex string.
signTx :: XPrv -> UnsignedTx -> Either SignTxError SignedTx
signTx xprv (UnsignedTx unsignedHex) = do
    rawBytes <-
        first (const InvalidHex) $
            Base16.decode $
                T.encodeUtf8 unsignedHex
    tx <-
        first (const InvalidTx) $
            deserializeTx rawBytes
    let signed = signLedgerTx xprv tx
    pure $
        SignedTx $
            T.decodeUtf8 $
                Base16.encode $
                    serializeTx signed

-- | Sign a ledger transaction, adding a key witness.
signLedgerTx
    :: XPrv -> L.Tx L.ConwayEra -> L.Tx L.ConwayEra
signLedgerTx xprv tx =
    tx
        & witsTxL . addrTxWitsL
            %~ Set.union
                ( Set.fromList
                    [mkKeyWitness (txIdTx tx) xprv]
                )

-- | Serialize a Conway-era transaction to CBOR.
serializeTx :: Tx ConwayEra -> ByteString
serializeTx =
    BL.toStrict
        . Ledger.serialize (eraProtVerLow @ConwayEra)

-- | Deserialize a Conway-era transaction from CBOR.
deserializeTx
    :: ByteString -> Either String (Tx ConwayEra)
deserializeTx bytes =
    first show
        $ decodeFullAnnotator
            (eraProtVerLow @ConwayEra)
            "ConwayTx"
            decCBOR
        $ BL.fromStrict bytes

-- * Internal

mkKeyWitness :: TxId -> XPrv -> WitVKey 'Witness
mkKeyWitness (TxId hash) xprv =
    WitVKey
        (toVKey xprv)
        ( fromXSig $
            HD.sign
                BS.empty
                xprv
                ( Crypto.getSignableRepresentation $
                    extractHash hash
                )
        )
    where
        fromXSig =
            Crypto.SignedDSIGN
                . fromMaybe
                    (error "rawDeserialiseSigDSIGN failed")
                . Crypto.rawDeserialiseSigDSIGN
                . HD.unXSignature

        toVKey :: XPrv -> VKey 'Witness
        toVKey =
            asWitness
                . VKey
                . fromMaybe
                    ( error
                        "rawDeserialiseVerKeyDSIGN failed"
                    )
                . Crypto.rawDeserialiseVerKeyDSIGN
                . HD.xpubPublicKey
                . HD.toXPub
