{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };


  outputs = { self, nixpkgs, home-manager }:
    let
      mkSystem = import ./lib/mksystem.nix;

    in
    {
      nixosConfigurations.qemu-aarch64 = mkSystem "qemu-aarch64" {
        inherit nixpkgs home-manager;
        system = "aarch64-linux";
        user = "flalanne";
        hostname = "vesta";
      };
    };
}
