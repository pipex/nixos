# My nixos configuration

Experiments with nixos for running on qemu

Build the derivation. The configured image will be stored in `./nixos-vm/result/`

```
cd ./nixos-vm && nix-build .
```

WIP

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
