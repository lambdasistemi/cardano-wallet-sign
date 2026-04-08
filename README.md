# cardano-wallet-sign

Cardano BIP39 wallet derivation and transaction signing CLI.

Derives Ed25519 signing keys from BIP39 mnemonics via CIP-1852 (BIP32-Ed25519)
and signs Conway-era Cardano transactions offline.

## Usage

```bash
# Generate a new wallet
cardano-wallet-sign generate -o wallet.json

# Show wallet address and owner hash
cardano-wallet-sign info -w wallet.json

# Sign a transaction (hex-encoded CBOR)
cardano-wallet-sign sign -w wallet.json --tx <hex>
```

The wallet file stores the BIP39 mnemonic. The signing key is derived on the fly
— no private key material is persisted on disk beyond the mnemonic.

## Building

Requires [Nix](https://nixos.org/) with flakes enabled.

```bash
nix build
nix develop  # enter dev shell
just build   # cabal build
just test    # run tests
just ci      # full local CI (build + test + format-check + hlint)
```

## Documentation

[Documentation site](https://lambdasistemi.github.io/cardano-wallet-sign/)

## License

Apache-2.0
