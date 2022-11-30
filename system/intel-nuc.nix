{ config, pkgs, lib, ... }: {
  imports = [
    ./shared.nix
  ];

  # Interface is this on my M1
  networking.interfaces.enp0s1.useDHCP = true;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;
}
