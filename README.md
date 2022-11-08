# My nixos configuration

Experiments with nixos for running on qemu

Download the iso installer

```
curl -L https://hydra.nixos.org/job/nixos/release-22.05-aarch64/nixos.iso_minimal.aarch64-linux/latest/download-by-type/file/iso > nixos-minimal-aarch64.iso
```

Load qemu

```
qemu-img create -f qcow2 nixos.qcow2 64G
```

Create drive image

```
qemu-img create -f qcow2 nixos.qcow2 64G
```

Boot nixos from iso image. This requires qemu 7.1.0 to use the vmnet-bridged interface.

```
sudo qemu-system-aarch64 -machine virt,highmem=off \
                         -cpu host -accel hvf -smp 4 -m 2048 \
                         -drive file=nixos.qcow2,format=qcow2,if=virtio,unit=0 \
                         -drive if=pflash,format=raw,unit=0,file=/nix/store/gcv8mkgvlywv6d9pllxc1hnwfll9i1b8-qemu-7.1.0/share/qemu/edk2-aarch64-code.fd,readonly=on \
                         -net nic,model=virtio -net vmnet-bridged,ifname=en0 \
                         -cdrom ./nixos-minimal-aarch64.iso \
                         -serial mon:stdio -nographic
```

Inside the image, run the bootstrap script. Answer yes to the prompts.

```
curl -sL https://raw.githubusercontent.com/pipex/nixos/main/bootstrap.sh
sh bootstrap.sh
```

TODO
