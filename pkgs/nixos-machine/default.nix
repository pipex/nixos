{ pkgs ? import <nixpkgs> { } }:
pkgs.stdenv.mkDerivation {
  name = "nixos-machine";
  buildInputs = [ pkgs.qemu pkgs.gettext ];
  builder = ./build.sh;
  qemu = pkgs.qemu;
  iso = pkgs.fetchurl {
    # find the latest release from hydra https://hydra.nixos.org/job/nixos/release-22.05-aarch64/nixos.iso_minimal.aarch64-linux/
    url = "https://hydra.nixos.org/job/nixos/release-22.05-aarch64/nixos.iso_minimal.aarch64-linux/latest/download-by-type/file/iso";
  };
  src = ./nixos-machine.tpl;
}
