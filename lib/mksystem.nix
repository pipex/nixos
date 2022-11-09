# This function creates a NixOS system based on our VM setup for a
# particular architecture.
name: { nixpkgs, home-manager, system, user, hostname }:

nixpkgs.lib.nixosSystem rec {
  inherit system;

  modules = [
    ../hardware/${name}.nix
    ../system/${name}.nix
    ../users/${user}/nixos.nix
    {
      # Replace the hostname by the user input
      networking.hostname = hostname;
    }
    home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.${user} = import ../users/${user}/home.nix;
    }

    # We expose some extra arguments so that our modules can parameterize
    # better based on these values.
    {
      config._module.args = {
        currentSystemName = name;
        currentSystem = system;
      };
    }
  ];
}
