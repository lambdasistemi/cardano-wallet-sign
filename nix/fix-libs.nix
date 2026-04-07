{ lib, pkgs, ... }:
{
  packages.cardano-crypto-praos.components.library.pkgconfig =
    lib.mkForce [ [ pkgs.libsodium-vrf ] ];
  packages.cardano-crypto-class.components.library.pkgconfig =
    lib.mkForce
    [ [ pkgs.libsodium-vrf pkgs.secp256k1 pkgs.libblst ] ];
}
