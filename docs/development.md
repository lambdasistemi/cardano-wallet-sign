# Development

## Prerequisites

- [Nix](https://nixos.org/) with flakes enabled

## Dev shell

```bash
nix develop
```

Provides GHC, cabal, fourmolu, cabal-fmt, and hlint.

## Just recipes

```bash
just build          # cabal build all -O0
just test           # run unit tests
just format         # format Haskell + cabal files
just format-check   # check formatting (CI mode)
just hlint          # run hlint
just ci             # full local CI gate
```

## Project structure

```
lib/
  Cardano/Wallet/
    CLI.hs          # Command-line parser (opt-env-conf)
    Derivation.hs   # BIP39 + CIP-1852 key derivation
    Sign.hs         # Conway-era transaction signing
    Types.hs        # Core types
exe/
  Main.hs           # CLI entry point
test/
  Main.hs           # Unit tests (hspec)
```

## CI

CI runs on a self-hosted NixOS runner with a shared Nix store. The build gate
job populates the store so downstream jobs (test, lint, format-check) are fast.

## Releases

Managed by [release-please](https://github.com/googleapis/release-please).
Conventional commit messages drive version bumps automatically.
