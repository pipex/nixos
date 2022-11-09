{ pkgs, ... }:

{
  users.users.flalanne = {
    isNormalUser = true;
    home = "/home/flalanne";
    shell = pkgs.zsh;
    extraGroups = [ "users" "docker" "wheel" ];
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPCSqTJlGCR0O65PUwCkJDK3+0VFUdH2OKz2NosAPrq1 flalanne" ];
  };

  services.getty.autologinUser = "flalanne";
}
