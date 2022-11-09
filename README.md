# My nixos configuration

Experiments with nixos for running on qemu

On a nix-enabled system.

```
cd pkgs/nixos-vm

# This may take some time as it needs to download the nixos iso
nix-env -i -f default.nix
```

Once that is ready

```
nixos-vm create --flake github:pipex/nixos#qemu-aarch64 default
nixos-vm start
```

Use environment variable `DEBUG=1` to track progress.
