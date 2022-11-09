{ pkgs ? import <nixpkgs> { } }:
pkgs.stdenv.mkDerivation {
  name = "nixos-vm";
  buildInputs = [ pkgs.qemu pkgs.gettext ];
  builder = ./build.sh;
  qemu = pkgs.qemu;
  iso = pkgs.fetchurl {
    # find the latest release from hydra https://hydra.nixos.org/job/nixos/release-22.05-aarch64/nixos.iso_minimal.aarch64-linux/
    url = "https://hydra.nixos.org/build/197933937/download/1/nixos-minimal-22.05.4035.8d467eecf4f-aarch64-linux.iso";
    # and get the hash using nix-prefetch-url <iso-url>
    sha256 = "1cix49l7z8vdxnafr2xh5l0bkr53d6cb9ha8jqf56f3x9s8s3nfz";
  };
  src = ./nixos-vm.tpl;
}
