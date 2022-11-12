{ pkgs ? import <nixpkgs> { } }:
pkgs.stdenv.mkDerivation {
  name = "nixos-machine";
  buildInputs = [ pkgs.qemu pkgs.gettext ];
  builder = ./build.sh;
  qemu = pkgs.qemu;
  iso = pkgs.fetchurl {
    # find the latest release from hydra https://hydra.nixos.org/job/nixos/release-22.05-aarch64/nixos.iso_minimal.aarch64-linux/
    url = "https://hydra.nixos.org/build/198441599/download/1/nixos-minimal-22.05.4093.cb8d3fe07d3-aarch64-linux.iso";
    # use nix-prefetc-url on the url above to get the sha
    sha256 = "0iwylh1cshdyf6yp26ikd8h7c8dy54yq97g64i4l1r7iy2rn2nm7";
    # Note that the iso's get deleted after a few days so this needs to be maintained. Once there are official aarch64 images
    # this should be much easier
  };
  src = ./nixos-machine.tpl;
}
