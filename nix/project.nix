{ pkgs, CHaP }:
let
  indexState = "2025-12-07T00:00:00Z";
  indexTool = { index-state = indexState; };
in
pkgs.haskell-nix.cabalProject' {
  name = "cardano-wallet-sign";
  src = ../. ;
  compiler-nix-name = "ghc984";
  shell = {
    tools = {
      cabal = indexTool;
      cabal-fmt = indexTool;
      fourmolu = indexTool;
      hlint = indexTool;
    };
    buildInputs = [
      pkgs.just
    ];
  };
  modules = [ (import ./fix-libs.nix) ];
  inputMap = {
    "https://chap.intersectmbo.org/" = CHaP;
  };
}
