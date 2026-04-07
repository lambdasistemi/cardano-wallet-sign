build:
    cabal build all -O0

test:
    cabal test all -O0 --test-show-details=direct

ci:
    just build
    just test
    just format-check
    just hlint

format:
    fourmolu -i $(find lib exe test -name '*.hs')
    cabal-fmt -i cardano-wallet-sign.cabal

format-check:
    fourmolu -m check $(find lib exe test -name '*.hs')
    cabal-fmt -c cardano-wallet-sign.cabal

hlint:
    hlint lib exe test
