{- |
Module      : Cardano.Wallet.CLI
Description : CLI command parser
License     : Apache-2.0
-}
module Cardano.Wallet.CLI (
    Command (..),
    commandParser,
    loadWallet,
) where

import Cardano.Wallet.Derivation (walletFromMnemonic)
import Cardano.Wallet.Types (Wallet)
import Data.Aeson qualified as Aeson
import Data.ByteString.Lazy qualified as BL
import Data.Text (Text)
import OptEnvConf (
    Parser,
    command,
    commands,
    env,
    help,
    long,
    metavar,
    option,
    reader,
    setting,
    short,
    str,
 )

-- | CLI commands.
data Command
    = Info FilePath
    | Sign FilePath Text
    deriving stock (Show, Eq)

-- | Top-level command parser.
commandParser :: Parser Command
commandParser =
    commands
        [ command
            "info"
            "Show wallet address and owner"
            $ Info <$> walletFileOption
        , command
            "sign"
            "Sign a transaction"
            $ Sign
                <$> walletFileOption
                <*> txHexOption
        ]

walletFileOption :: Parser FilePath
walletFileOption =
    setting
        [ help "Path to wallet JSON file"
        , env "CARDANO_WALLET_FILE"
        , metavar "FILEPATH"
        , long "wallet"
        , short 'w'
        , reader str
        , option
        ]

txHexOption :: Parser Text
txHexOption =
    setting
        [ help
            "Hex-encoded unsigned transaction"
        , metavar "HEX"
        , long "tx"
        , reader str
        , option
        ]

-- | Load a wallet from a JSON file.
loadWallet :: FilePath -> IO Wallet
loadWallet path = do
    bs <- BL.readFile path
    case Aeson.decode bs of
        Nothing ->
            fail $
                "Cannot parse wallet: " <> path
        Just (WalletFile m) ->
            case walletFromMnemonic m of
                Left err ->
                    fail $
                        "Derivation error: "
                            <> show err
                Right w -> pure w

newtype WalletFile = WalletFile Text

instance Aeson.FromJSON WalletFile where
    parseJSON =
        Aeson.withObject "WalletFile" $ \o ->
            WalletFile <$> o Aeson..: "mnemonics"
