#!/bin/sh

set -e

[ -f "$stdenv/setup" ] && . $stdenv/setup

# Set global variables for other environments
TMPDIR="${TMPDIR:-/tmp}"
DEBUG="${DEBUG:-1}"

# Default arguments
qemu="${qemu:-/usr/local}"
iso="${src:-./nixos-minimal-aarch64.iso}"
imgSize="${imgSize:-64G}"

mkdir -p $out 2>/dev/null || out="."

nixos_iso_dl() {
	iso="${1:-./nixos-minimal-aarch64.iso}"
	curl -sL https://hydra.nixos.org/job/nixos/release-22.05-aarch64/nixos.iso_minimal.aarch64-linux/latest/download-by-type/file/iso >$iso
}

nixos_img_create() {
	img="${1:-./nixos.qcow2}"
	size="${2:-64G}"
	echo "Creating image $img" >&2
	qemu-img create -f qcow2 "$img" "$size" >/dev/null
}

nixos_bootstrap() {
	iso="${1:-./nixos-minimal-aarch64.iso}"
	img="${2:-./nixos.qcow2}"
	size="${3:-64G}"

	[ ! -f "$iso" ] && nixos_iso_dl "$iso"
	[ ! -f "$img" ] && nixos_img_create "$img" "$size"

	# Create named pipes to talk to the guest
	[ ! -p "$TMPDIR/guest.in" ] && mkfifo "$TMPDIR/guest.in"
	[ ! -p "$TMPDIR/guest.out" ] && mkfifo "$TMPDIR/guest.out"

	echo "Starting VM for bootstraping" >&2
	qemu-system-aarch64 -machine virt,highmem=off \
		-cpu host -accel hvf -smp 4 -m 2048 \
		-drive file=$img,format=qcow2,if=virtio,unit=0 \
		-drive if=pflash,format=raw,unit=0,file=$qemu/share/qemu/edk2-aarch64-code.fd,readonly=on \
		-net nic,model=virtio -net user \
		-cdrom $iso \
		-serial pipe:$TMPDIR/guest -monitor none -nographic &

	qemu_pid=$!

	while read -r line; do
		[ "$DEBUG" = "1" ] && echo "$line"
		# Wait for the login prompt
		if [ -z "${line##nixos login:*}" ]; then
			break
		fi
	done <"$TMPDIR/guest.out"

	# Print the rest of the output
	if [ "$DEBUG" = "1" ]; then
		cat <"$TMPDIR/guest.out" &
		cat_pid=$!
	fi

	# First boot configuration. The root user will login automatically but
	# this will be changed later by the reconfiguration step
	configuration='nix.package = pkgs.nixUnstable;\\n \
			nix.extraOptions = \\"experimental-features = nix-command flakes\\";\\n \
	    services.openssh.passwordAuthentication = false;\\n \
	    services.openssh.permitRootLogin = \\"no\\";\\n \
	    services.openssh.enable = true;\\n \
	    services.mingetty.autologinUser = \\"root\\";\\n \
	  '

	# partition drive
	echo "Partitioning virtual drive" >&2
	printf "sudo -- sh -c \" \
 		parted -s /dev/vda -- mklabel gpt; \
 		parted -s /dev/vda -- mkpart primary 512MiB -8GiB; \
 		parted -s /dev/vda -- mkpart primary linux-swap -8GiB 100%%; \
 		parted -s /dev/vda -- mkpart ESP fat32 1MiB 512MiB; \
 		parted -s /dev/vda -- set 3 esp on; \
 		sleep 1; \
 		mkfs.ext4 -F -L nixos /dev/vda1; \
 		mkswap -L swap /dev/vda2; \
 		mkfs.fat -F 32 -n boot /dev/vda3; \
 		sleep 1; \
 		mount /dev/disk/by-label/nixos /mnt; \
 		mkdir -p /mnt/boot; \
 		mount /dev/disk/by-label/boot /mnt/boot; \
 		nixos-generate-config --root /mnt; \
 		sed --in-place '/system\\.stateVersion = .*/a \
 			$configuration \
 		' /mnt/etc/nixos/configuration.nix; \
 		nixos-install --no-root-passwd; \
 		shutdown now \
 		\"\n" >"$TMPDIR/guest.in"

	# TODO: kill $cat_pid
	# TODO: wait for reboot
	# TODO: download configuration from github
	# TODO: setup using flake

	wait $qemu_pid
}

nixos_bootstrap "$iso" "$out/nixos.qcow2" "$imgSize"
