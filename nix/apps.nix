{ pkgs, checks }:
let
  runnable = {
    inherit (checks) exe tests lint;
  };
in
builtins.mapAttrs
  (_: check: {
    type = "app";
    program = pkgs.lib.getExe check;
  })
  runnable
