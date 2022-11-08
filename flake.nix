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
      system = "aarch64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      hostname = "vesta";
    in
    {
      formatter.${system} = pkgs.nixpkgs-fmt;
      defaultPackage.aarch64-linux = home-manager.defaultPackage.aarch64-linux;
      nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ ./nixos/configuration.nix ];
      };

      homeConfigurations.${hostname} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules = [
          ./home.nix
        ];
      };
    };


}
