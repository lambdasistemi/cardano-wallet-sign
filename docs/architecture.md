# Architecture

## Derivation path

Keys are derived following [CIP-1852](https://cips.cardano.org/cip/CIP-1852/)
using BIP32-Ed25519:

```
m / 1852' / 1815' / 0' / 0 / 0
    purpose   coin   account  role  index
```

The derivation chain:

1. BIP39 mnemonic (15 words) → seed entropy
2. Seed → BIP32-Ed25519 root key
3. Root key → account key (hardened derivation)
4. Account key → payment key (soft derivation)
5. Payment public key → Blake2b_224 hash → Shelley enterprise address

## Signing

Transaction signing:

1. Decode the hex-encoded CBOR into a Conway-era transaction body
2. Compute the transaction body hash
3. Sign the hash with the derived Ed25519 private key
4. Attach the witness (public key + signature) to the transaction
5. Re-encode as hex CBOR

## Wallet file format

```json
{ "mnemonics": "word1 word2 ... word15" }
```

The wallet file stores only the mnemonic. All key material is derived at
runtime from the mnemonic and discarded after use. This avoids persisting
private key bytes on disk.
