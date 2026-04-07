module Main (main) where

import Cardano.Wallet.CLI (
    Command (..),
    commandParser,
 )
import Cardano.Wallet.Derivation (walletFromMnemonic)
import Cardano.Wallet.Types (
    Address (..),
    Owner (..),
    Wallet (..),
 )
import Data.Map.Strict qualified as Map
import Data.Set qualified as Set
import Data.Text (Text)
import OptEnvConf (runParserOn)
import OptEnvConf.Args (parseArgs)
import OptEnvConf.Capability (Capabilities (..))
import OptEnvConf.EnvMap (EnvMap (..))
import Test.Hspec (
    Spec,
    describe,
    hspec,
    it,
    shouldBe,
 )

mnemonic :: Text
mnemonic =
    "rug silver nice monitor \
    \scorpion chase tunnel stone \
    \bleak time twelve enough"

main :: IO ()
main = hspec $ do
    derivationSpec
    parserSpec

derivationSpec :: Spec
derivationSpec = describe "Wallet derivation" $ do
    it "derives correct address" $ do
        case walletFromMnemonic mnemonic of
            Left err ->
                fail $ show err
            Right w ->
                unAddress (walletAddress w)
                    `shouldBe` "addr_test1vz6zuvdm0gu3q54pk50wjfjwyt4mwj6uaelzdfh9extxgnqyycgv0"

    it "derives correct owner" $ do
        case walletFromMnemonic mnemonic of
            Left err ->
                fail $ show err
            Right w ->
                unOwner (walletOwner w)
                    `shouldBe` "b42e31bb7a391052a1b51ee9264e22ebb74b5cee7e26a6e5c996644c"

parse :: [String] -> [(String, String)] -> IO Command
parse args envVars = do
    result <-
        runParserOn
            (Capabilities Set.empty)
            Nothing
            commandParser
            (parseArgs args)
            (EnvMap $ Map.fromList envVars)
            Nothing
    case result of
        Left errs ->
            fail $ "Parse error: " <> show errs
        Right cmd -> pure cmd

parserSpec :: Spec
parserSpec = describe "CLI parser" $ do
    it "parses info command" $ do
        cmd <- parse ["info", "--wallet", "w.json"] []
        cmd `shouldBe` Info "w.json"

    it "parses info with -w shorthand" $ do
        cmd <- parse ["info", "-w", "w.json"] []
        cmd `shouldBe` Info "w.json"

    it "parses sign command" $ do
        cmd <-
            parse
                [ "sign"
                , "--wallet"
                , "w.json"
                , "--tx"
                , "deadbeef"
                ]
                []
        cmd `shouldBe` Sign "w.json" "deadbeef"

    it "parses wallet from env var" $ do
        cmd <-
            parse
                ["info"]
                [("CARDANO_WALLET_FILE", "/tmp/w.json")]
        cmd `shouldBe` Info "/tmp/w.json"
