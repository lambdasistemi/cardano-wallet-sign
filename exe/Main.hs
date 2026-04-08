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
 )
import Cardano.Wallet.Derivation (generateMnemonic)
import Cardano.Wallet.Types (
    Address (..),
    Owner (..),
    SignedTx (..),
    UnsignedTx (..),
    Wallet (..),
 )
import Data.Aeson qualified as Aeson
import Data.ByteString.Lazy qualified as BL
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

cmdGenerate :: FilePath -> IO ()
cmdGenerate path = do
    mnemonic <- generateMnemonic
    BL.writeFile path $
        Aeson.encode $
            Aeson.object
                [("mnemonics", Aeson.toJSON mnemonic)]
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
