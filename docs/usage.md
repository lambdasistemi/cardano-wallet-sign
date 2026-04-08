# Usage

## Commands

### generate

Create a new wallet with a random 15-word BIP39 mnemonic.

```bash
cardano-wallet-sign generate -o wallet.json
```

Output:

```
address: addr_test1v...
owner:   abcdef1234...
wallet:  wallet.json
```

The wallet file is a JSON object containing the mnemonic:

```json
{ "mnemonics": "word1 word2 ... word15" }
```

!!! warning
    The wallet file contains the mnemonic in plaintext. Protect it accordingly.

### info

Display the address and owner hash for an existing wallet.

```bash
cardano-wallet-sign info -w wallet.json
# or via environment variable
CARDANO_WALLET_FILE=wallet.json cardano-wallet-sign info
```

### sign

Sign a hex-encoded unsigned transaction CBOR.

```bash
cardano-wallet-sign sign -w wallet.json --tx 84a400...
```

Outputs the hex-encoded signed transaction CBOR to stdout.

## Options

| Flag | Env var | Description |
|------|---------|-------------|
| `-w`, `--wallet` | `CARDANO_WALLET_FILE` | Path to wallet JSON file |
| `-o`, `--output` | — | Output path for generated wallet |
| `--tx` | — | Hex-encoded unsigned transaction |

## Integration with cardano-cli

```bash
# Build a transaction with cardano-cli
cardano-cli conway transaction build-raw ... --out-file tx.unsigned

# Extract hex
TX_HEX=$(xxd -p tx.unsigned | tr -d '\n')

# Sign with cardano-wallet-sign
SIGNED=$(cardano-wallet-sign sign -w wallet.json --tx "$TX_HEX")

# Submit
echo -n "$SIGNED" | xxd -r -p > tx.signed
cardano-cli conway transaction submit --tx-file tx.signed
```
