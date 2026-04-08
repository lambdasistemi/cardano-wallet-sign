{- |
Module      : Cardano.Wallet.CLI
Description : CLI command parser
License     : Apache-2.0
-}
module Cardano.Wallet.CLI (
    Command (..),
    commandParser,
    loadWallet,
    promptPassphrase,
) where

import Cardano.Wallet.Derivation (walletFromMnemonic)
import Cardano.Wallet.Encrypt (
    WalletFile (..),
    decryptMnemonic,
    readWalletFile,
 )
import Cardano.Wallet.Types (Wallet)
import Data.ByteString.Char8 qualified as BS
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
import System.IO (
    hFlush,
    hGetEcho,
    hSetEcho,
    stdin,
    stdout,
 )

-- | CLI commands.
data Command
    = Generate FilePath
    | Info FilePath
    | Sign FilePath Text
    | Encrypt FilePath
    | Decrypt FilePath
    deriving stock (Show, Eq)

-- | Top-level command parser.
commandParser :: Parser Command
commandParser =
    commands
        [ command
            "generate"
            "Generate a new wallet"
            $ Generate <$> outputFileOption
        , command
            "info"
            "Show wallet address and owner"
            $ Info <$> walletFileOption
        , command
            "sign"
            "Sign a transaction"
            $ Sign
                <$> walletFileOption
                <*> txHexOption
        , command
            "encrypt"
            "Encrypt a wallet file"
            $ Encrypt <$> walletFileOption
        , command
            "decrypt"
            "Decrypt a wallet file"
            $ Decrypt <$> walletFileOption
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

outputFileOption :: Parser FilePath
outputFileOption =
    setting
        [ help "Path to write wallet JSON file"
        , metavar "FILEPATH"
        , long "output"
        , short 'o'
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

{- | Load a wallet from a JSON file.

Detects encrypted wallets and prompts for
passphrase when needed.
-}
loadWallet :: FilePath -> IO Wallet
loadWallet path = do
    wf <- readWalletFile path
    mnemonic <- case wf of
        Plaintext m -> pure m
        Encrypted{} -> do
            pass <- promptPassphrase "Passphrase: "
            case decryptMnemonic pass wf of
                Left err ->
                    fail $
                        "Decryption error: "
                            <> show err
                Right m -> pure m
    case walletFromMnemonic mnemonic of
        Left err ->
            fail $
                "Derivation error: " <> show err
        Right w -> pure w

-- | Prompt for a passphrase with echo disabled.
promptPassphrase :: String -> IO BS.ByteString
promptPassphrase prompt = do
    putStr prompt
    hFlush stdout
    old <- hGetEcho stdin
    hSetEcho stdin False
    pass <- BS.getLine
    hSetEcho stdin old
    putStrLn ""
    pure pass
