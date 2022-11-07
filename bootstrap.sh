#!/bin/sh

set -e

confirm() {
	# call with a prompt string or use a default
	prompt="${1:-Are you sure? [y/N]}"
	printf "%s " "$prompt"
	read -r response
	case "$response" in
	[yY][eE][sS] | [yY])
		true
		;;
	*)
		false
		;;
	esac
}

for dev in "/dev/sda" "/dev/vda"; do
	sudo fdisk -l $dev && device=$dev && break
done

if [ "$device" = "" ]; then
	echo "Install media could not be detected." >&2
	exit 1
fi

if ! confirm "This will setup partitions and initial configuration for a nixos system. Any existing partitions will be lost. Are you sure you want to continue?"; then
	echo "Install interrupted. Nothing has been done." >&2
	exit 1
fi

# Partition the drive
sudo -- sh -c "\
		parted $device -- mklabel gpt; \
		parted $device -- mkpart primary 512MiB -8GiB; \
		parted $device -- mkpart primary linux-swap -8GiB 100\%; \
		parted $device -- mkpart ESP fat32 1MiB 512MiB; \
		parted $device -- set 3 esp on; \
		sleep 1; \
		mkfs.ext4 -L nixos ${device}1; \
		mkswap -L swap ${device}2; \
		mkfs.fat -F 32 -n boot ${device}3; \
		sleep 1; \
		mount /dev/disk/by-label/nixos /mnt; \
		mkdir -p /mnt/boot; \
		mount /dev/disk/by-label/boot /mnt/boot; \
		nixos-generate-config --root /mnt; \
		sed --in-place '/system\.stateVersion = .*/a \
			nix.package = pkgs.nixUnstable;\n \
			nix.extraOptions = \"experimental-features = nix-command flakes\";\n \
  		services.openssh.enable = true;\n \
			services.openssh.passwordAuthentication = false;\n \
			services.openssh.permitRootLogin = \"no\";\n \
		' /mnt/etc/nixos/configuration.nix; \
		nixos-install --no-root-passwd
		"

confirm "Install ready. Reboot?" && sudo reboot
