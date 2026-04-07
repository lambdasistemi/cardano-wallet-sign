{ pkgs, components, shell }:
{
  library = components.library;
  exe = components.exes.cardano-wallet-sign;
  tests = components.tests.unit-tests;
  lint = pkgs.writeShellApplication {
    name = "lint";
    runtimeInputs = shell.nativeBuildInputs;
    excludeShellChecks = [ "SC2046" "SC2086" ];
    text = ''
      cd "${../. + "/"}"
      fourmolu -m check $(find lib exe test -name '*.hs')
      cabal-fmt -c cardano-wallet-sign.cabal
      hlint lib exe test
    '';
  };
}
