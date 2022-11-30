{ config, pkgs, lib, ... }: {
  imports = [
    ./shared.nix
  ];

  networking.interfaces.enp0s1.useDHCP = true;

  # Qemu
  services.spice-vdagentd.enable = true;
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;
}
