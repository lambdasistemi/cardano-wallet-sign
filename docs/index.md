# cardano-wallet-sign

Cardano BIP39 wallet derivation and transaction signing library and CLI.

## Overview

`cardano-wallet-sign` derives Ed25519 signing keys from BIP39 mnemonics
following the CIP-1852 derivation path (BIP32-Ed25519) and signs Conway-era
Cardano transactions offline.

Key properties:

- **Mnemonic-only storage** — wallet files contain only the BIP39 mnemonic;
  private keys are derived on the fly and never persisted
- **Offline signing** — transactions are signed locally without network access
- **Conway-era support** — produces witness sets compatible with the current
  Cardano ledger era

## Quick start

```bash
# Install via nix
nix build github:lambdasistemi/cardano-wallet-sign

# Generate a wallet
cardano-wallet-sign generate -o wallet.json

# Sign a transaction
cardano-wallet-sign sign -w wallet.json --tx <hex-encoded-cbor>
```

## Modules

| Module | Description |
|--------|-------------|
| `Cardano.Wallet.Derivation` | BIP39 mnemonic generation and CIP-1852 key derivation |
| `Cardano.Wallet.Sign` | Conway-era transaction signing |
| `Cardano.Wallet.Types` | Core types: `Wallet`, `Address`, `Owner`, `UnsignedTx`, `SignedTx` |
| `Cardano.Wallet.CLI` | Command-line parser |
