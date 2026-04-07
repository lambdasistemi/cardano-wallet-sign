{
  description =
    "Cardano BIP39 wallet derivation and transaction signing";
  nixConfig = {
    extra-substituters = [ "https://cache.iog.io" ];
    extra-trusted-public-keys =
      [ "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ=" ];
  };
  inputs = {
    haskellNix.url =
      "github:input-output-hk/haskell.nix/baa6a549ce876e9c44c494a12116f178f1becbe6";
    nixpkgs.follows = "haskellNix/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    iohkNix = {
      url =
        "github:input-output-hk/iohk-nix/0ce7cc21b9a4cfde41871ef486d01a8fafbf9627";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    CHaP = {
      url =
        "github:intersectmbo/cardano-haskell-packages/a46182e9c039737bf43cdb5286df49bbe0edf6fb";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, haskellNix, iohkNix
    , CHaP, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-darwin" ];
      perSystem = { system, ... }:
        let
          pkgs = import nixpkgs {
            overlays = [
              iohkNix.overlays.crypto
              haskellNix.overlay
              iohkNix.overlays.haskell-nix-crypto
              iohkNix.overlays.cardano-lib
            ];
            inherit system;
          };
          project = import ./nix/project.nix {
            inherit pkgs CHaP;
          };
          shell = project.shell;
          components =
            project.hsPkgs.cardano-wallet-sign.components;
          checks = import ./nix/checks.nix {
            inherit pkgs components shell;
          };
        in {
          devShells.default = shell;
          packages.default = components.exes.cardano-wallet-sign;
          inherit checks;
          apps = import ./nix/apps.nix {
            inherit pkgs checks;
          };
        };
    };
}
