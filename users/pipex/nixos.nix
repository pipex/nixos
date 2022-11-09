{ pkgs, ... }:

{
  users.users.mitchellh = {
    isNormalUser = true;
    home = "/home/pipex";
    shell = pkgs.zsh;
    extraGroups = [ "docker" "wheel" ];
    openssh.authorizedKeys.keyFiles = [ (builtins.fetchurl https://github.com/pipex.keys) ];
  };

  services.mingetty.autologinUser = "flalanne";
}
