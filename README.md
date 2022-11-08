# My nixos configuration

Experiments with nixos for running on qemu

Download the iso installer

```
curl -L https://hydra.nixos.org/job/nixos/release-22.05-aarch64/nixos.iso_minimal.aarch64-linux/latest/download-by-type/file/iso > ./nixos-vm/nixos-minimal-aarch64.iso
```

Build the derivation. The configured image will be stored in `./nixos-vm/result/`

```
cd ./nixos-vm && nix-build .
```

WIP
