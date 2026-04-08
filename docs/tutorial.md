# Tutorial

A step-by-step walkthrough of wallet creation, encryption, and
transaction signing on Cardano testnet.

## Prerequisites

```bash
# Install cardano-wallet-sign
nix build github:lambdasistemi/cardano-wallet-sign
export PATH="./result/bin:$PATH"

# You'll also need cardano-cli for building transactions
```

## 1. Generate a wallet

```bash
cardano-wallet-sign generate -o wallet.json
```

Output:

```
address: addr_test1vz6zuv...
owner:   b42e31bb7a39...
wallet:  wallet.json
```

The address is a bech32 Shelley enterprise address. The owner is
the Blake2b_224 hash of the public key (hex).

!!! warning
    The wallet file contains your mnemonic in plaintext.
    Encrypt it immediately (see step 2).

## 2. Encrypt the wallet

```bash
cardano-wallet-sign encrypt -w wallet.json
```

You will be prompted for a passphrase (twice for confirmation).
The file is encrypted in place using AES-256-GCM.

Verify it worked:

```bash
cat wallet.json
# {"encrypted":"...","iv":"...","salt":"...","tag":"..."}
```

## 3. Check wallet info

```bash
cardano-wallet-sign info -w wallet.json
```

If the wallet is encrypted, you will be prompted for the passphrase.

## 4. Fund the wallet

Go to the [Cardano testnet faucet](https://docs.cardano.org/cardano-testnets/tools/faucet/)
and send test ADA to your address.

## 5. Build a transaction

Use `cardano-cli` to build an unsigned transaction:

```bash
# Query UTxOs
cardano-cli conway query utxo \
    --address "$(cardano-wallet-sign info -w wallet.json \
        | grep address | awk '{print $2}')" \
    --testnet-magic 1

# Build the transaction (adjust UTxO, amounts, addresses)
cardano-cli conway transaction build-raw \
    --tx-in TX_HASH#TX_IX \
    --tx-out RECIPIENT_ADDR+AMOUNT \
    --tx-out YOUR_ADDR+CHANGE \
    --fee FEE \
    --out-file tx.unsigned
```

## 6. Sign the transaction

Extract the CBOR hex and sign:

```bash
TX_HEX=$(xxd -p tx.unsigned | tr -d '\n')

SIGNED=$(cardano-wallet-sign sign -w wallet.json --tx "$TX_HEX")
```

You will be prompted for the passphrase if the wallet is encrypted.

## 7. Submit the transaction

```bash
echo -n "$SIGNED" | xxd -r -p > tx.signed

cardano-cli conway transaction submit \
    --tx-file tx.signed \
    --testnet-magic 1
```

## 8. Decrypt the wallet (optional)

If you need the plaintext mnemonic back:

```bash
cardano-wallet-sign decrypt -w wallet.json
```

## Environment variable

You can set `CARDANO_WALLET_FILE` to avoid passing `-w` every time:

```bash
export CARDANO_WALLET_FILE=wallet.json

cardano-wallet-sign info
cardano-wallet-sign sign --tx "$TX_HEX"
```
