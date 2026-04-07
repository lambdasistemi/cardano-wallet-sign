{- |
Module      : Cardano.Wallet.Types
Description : Wallet and transaction types
License     : Apache-2.0
-}
module Cardano.Wallet.Types (
    -- * Wallet
    Wallet (..),

    -- * Transaction
    UnsignedTx (..),
    SignedTx (..),
    SignTxError (..),

    -- * Identity
    Address (..),
    Owner (..),
) where

import Data.Text (Text)

-- | A derived Cardano wallet.
data Wallet = Wallet
    { walletAddress :: Address
    -- ^ Shelley payment address (bech32)
    , walletOwner :: Owner
    -- ^ Blake2b_224 hash of public key (hex)
    , walletSign :: UnsignedTx -> Either SignTxError SignedTx
    -- ^ Sign an unsigned transaction
    }

instance Show Wallet where
    show w =
        "Wallet { address = "
            <> show (walletAddress w)
            <> ", owner = "
            <> show (walletOwner w)
            <> " }"

-- | Bech32-encoded Shelley payment address.
newtype Address = Address {unAddress :: Text}
    deriving newtype (Show, Eq, Ord)

-- | Hex-encoded Blake2b_224 hash of the public key.
newtype Owner = Owner {unOwner :: Text}
    deriving newtype (Show, Eq, Ord)

-- | Hex-encoded unsigned transaction CBOR.
newtype UnsignedTx = UnsignedTx {unUnsignedTx :: Text}
    deriving newtype (Show, Eq)

-- | Hex-encoded signed transaction CBOR.
newtype SignedTx = SignedTx {unSignedTx :: Text}
    deriving newtype (Show, Eq)

-- | Transaction signing errors.
data SignTxError
    = InvalidHex
    | InvalidTx
    deriving stock (Show, Eq)
