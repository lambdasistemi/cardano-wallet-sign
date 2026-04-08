{- |
Module      : Main
Description : Cardano wallet signing CLI
License     : Apache-2.0
-}
module Main (main) where

import Cardano.Wallet.CLI (
    Command (..),
    commandParser,
    loadWallet,
    promptPassphrase,
 )
import Cardano.Wallet.Derivation (generateMnemonic)
import Cardano.Wallet.Encrypt (
    WalletFile (..),
    decryptMnemonic,
    encryptMnemonic,
    readWalletFile,
    writeWalletFile,
 )
import Cardano.Wallet.Types (
    Address (..),
    Owner (..),
    SignedTx (..),
    UnsignedTx (..),
    Wallet (..),
 )
import Data.Text (Text, pack)
import Data.Text.IO qualified as T
import OptEnvConf (runParser)
import Paths_cardano_wallet_sign (version)
import System.Exit (exitFailure)
import System.IO (hPutStrLn, stderr)

main :: IO ()
main = do
    cmd <-
        runParser
            version
            "Cardano wallet signing tool"
            commandParser
    case cmd of
        Generate path -> cmdGenerate path
        Info path -> cmdInfo path
        Sign path hexTx -> cmdSign path hexTx
        Encrypt path -> cmdEncrypt path
        Decrypt path -> cmdDecrypt path

cmdGenerate :: FilePath -> IO ()
cmdGenerate path = do
    mnemonic <- generateMnemonic
    writeWalletFile path (Plaintext mnemonic)
    w <- loadWallet path
    T.putStrLn $
        "address: "
            <> unAddress (walletAddress w)
    T.putStrLn $
        "owner:   "
            <> unOwner (walletOwner w)
    T.putStrLn $ "wallet:  " <> pack path

cmdInfo :: FilePath -> IO ()
cmdInfo path = do
    w <- loadWallet path
    T.putStrLn $
        "address: "
            <> unAddress (walletAddress w)
    T.putStrLn $
        "owner:   "
            <> unOwner (walletOwner w)

cmdSign :: FilePath -> Text -> IO ()
cmdSign path hexTx = do
    w <- loadWallet path
    case walletSign w (UnsignedTx hexTx) of
        Left err -> do
            hPutStrLn stderr $
                "Sign error: " <> show err
            exitFailure
        Right (SignedTx signed) ->
            T.putStrLn signed

cmdEncrypt :: FilePath -> IO ()
cmdEncrypt path = do
    wf <- readWalletFile path
    case wf of
        Encrypted{} -> do
            hPutStrLn stderr "Already encrypted"
            exitFailure
        Plaintext mnemonic -> do
            pass <- promptPassphrase "Passphrase: "
            confirm <-
                promptPassphrase "Confirm: "
            if pass /= confirm
                then do
                    hPutStrLn
                        stderr
                        "Passphrases do not match"
                    exitFailure
                else do
                    encrypted <-
                        encryptMnemonic pass mnemonic
                    writeWalletFile path encrypted
                    T.putStrLn "Wallet encrypted"

cmdDecrypt :: FilePath -> IO ()
cmdDecrypt path = do
    wf <- readWalletFile path
    case wf of
        Plaintext{} -> do
            hPutStrLn stderr "Not encrypted"
            exitFailure
        Encrypted{} -> do
            pass <- promptPassphrase "Passphrase: "
            case decryptMnemonic pass wf of
                Left err -> do
                    hPutStrLn stderr $
                        "Decryption error: "
                            <> show err
                    exitFailure
                Right mnemonic -> do
                    writeWalletFile
                        path
                        (Plaintext mnemonic)
                    T.putStrLn "Wallet decrypted"
