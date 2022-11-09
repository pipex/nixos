{ pkgs, ... }:

{
  users.users.mitchellh = {
    isNormalUser = true;
    home = "/home/pipex";
    shell = pkgs.zsh;
    extraGroups = [ "docker" "wheel" ];
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPCSqTJlGCR0O65PUwCkJDK3+0VFUdH2OKz2NosAPrq1 flalanne" ];
  };

  services.mingetty.autologinUser = "flalanne";
}
