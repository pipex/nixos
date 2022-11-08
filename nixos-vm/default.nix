{ pkgs ? import <nixpkgs> { } }:
pkgs.stdenv.mkDerivation {
  name = "nixos-vm";
  buildInputs = [ pkgs.qemu pkgs.curl ];
  builder = ./bootstrap.sh;
  qemu = pkgs.qemu;
  # TODO: fetch the iso from the web instead of having
  # it be a dependency
  iso = ./nixos-minimal-aarch64.iso;
  imgSize = "64G";
}
