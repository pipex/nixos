{ config, pkgs, lib, ... }: {
  imports = [
    ./shared.nix
  ];

  # Interface is this on my M1
  networking.interfaces.enp0s1.useDHCP = true;

  # Qemu
  services.spice-vdagentd.enable = true;

  # Lots of stuff that uses aarch64 that claims doesn't work, but actually works.
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;

  # Share our host filesystem
  # TODO
  # fileSystems."/host" = {
  #   fsType = "fuse./run/current-system/sw/bin/vmhgfs-fuse";
  #   device = ".host:/";
  #   options = [
  #     "umask=22"
  #     "uid=1000"
  #     "gid=1000"
  #     "allow_other"
  #     "auto_unmount"
  #     "defaults"
  #   ];
  # };
}
