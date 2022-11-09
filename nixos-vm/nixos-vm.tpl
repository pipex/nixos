#!/bin/sh

set -e

# XDG vars
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Additional environment
PATH="${qemu}/bin:$PATH"
TMPDIR="${TMPDIR:-/tmp}"
DEBUG="${DEBUG:-1}"

# Home for nixos images
NIXOS_VM_HOME="$XDG_STATE_HOME/nixos-vm"

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

create() {
	imgSize="64G"
	while :; do
		case $1 in
		-s | --size) # Takes an option argument, ensuring it has been specified.
			if [ -n "$2" ]; then
				imgSize=$2
				shift
			else
				echo "Error: '--size' requires a non-empty option argument." >&2
				exit 1
			fi
			shift
			break
			;;
		-?*)
			printf "Warn: Ignoring unrecognized argument argument %s." "$1" >&2
			shift
			;;
		*) # Default case: If no more options then break out of the loop.
			break ;;
		esac

		shift
	done

	# Whatever argument is left must be the name
	imgName="${1:-default}"
	img="$NIXOS_VM_HOME/$imgName.qcow2"

	# Check for the file before doing anything
	[ -f "$img" ] && echo "Error: a virtual machine with name '$imgName' already exists. Please run 'nixos-vm destroy $imgName' before calling 'create'." >&2 && exit 1

	# Create the home directory
	mkdir -p "$NIXOS_VM_HOME"

	echo "Creating image for '$imgName' VM" >&2
	qemu-img create -f qcow2 "$img" "$imgSize" >/dev/null

	# Create named pipes to talk to the guest
	[ ! -p "$TMPDIR/guest.in" ] && mkfifo "$TMPDIR/guest.in"
	[ ! -p "$TMPDIR/guest.out" ] && mkfifo "$TMPDIR/guest.out"

	echo "Starting VM for bootstraping" >&2
	qemu-system-aarch64 -machine virt,highmem=off \
		-cpu host -accel hvf -smp 4 -m 2048 \
		-drive "file=$img,format=qcow2,if=virtio,unit=0" \
		-drive if=pflash,format=raw,unit=0,file=${qemu}/share/qemu/edk2-aarch64-code.fd,readonly=on \
		-net nic,model=virtio -net user \
		-cdrom ${iso} \
		-serial "pipe:$TMPDIR/guest" -monitor none -nographic &

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
 		reboot \
 		\"\n" >"$TMPDIR/guest.in"

	# kill cat
	[ -n "$cat_pid" ] && kill -9 $cat_pid >/dev/null 2>&1

	# wait for reboot
	while read -r line; do
		[ "$DEBUG" = "1" ] && echo "$line"
		# Wait for the login prompt
		if [ -z "${line##nixos login:*}" ]; then
			break
		fi
	done <"$TMPDIR/guest.out"

	# TODO: setup using flake
	printf "shutdown now\n" >"$TMPDIR/guest.in"

	wait $qemu_pid
}

run() {
	iface="en0"
	while :; do
		case $1 in
		-i | --iface) # Takes an option argument, ensuring it has been specified.
			if [ -n "$2" ]; then
				iface=$2
				shift
			else
				echo "Error: '--iface' requires a non-empty option argument." >&2
				exit 1
			fi
			shift
			break
			;;
		-?*)
			echo "Error: Unrecognized argument %s." "$1" >&2
			shift
			;;
		*) # Default case: If no more options then break out of the loop.
			break ;;
		esac

		shift
	done

	# Whatever argument is left must be the name
	imgName="${1:-default}"
	img="$NIXOS_VM_HOME/$imgName.qcow2"

	# Check for the file before doing anything
	[ ! -f "$img" ] && echo "Error: No virtual machine '$imgName' found.. Please run 'nixos-vm create $imgName'." >&2 && exit 1

	qemu-system-aarch64 -machine virt,highmem=off \
		-cpu host -accel hvf -smp 4 -m 2048 \
		-drive "file=$img,format=qcow2,if=virtio,unit=0" \
		-drive "if=pflash,format=raw,unit=0,file=${qemu}/share/qemu/edk2-aarch64-code.fd,readonly=on" \
		-net nic,model=virtio -net "vmnet-bridged,ifname=$iface" \
		-serial mon:stdio -nographic
}

destroy() {
	imgName="${1:-default}"
	img="$NIXOS_VM_HOME/$imgName.qcow2"

	# Check for the file before doing anything
	[ ! -f "$img" ] && echo "No virtual machine '$imgName' found. Nothing was done'." >&2 && exit 1

	if confirm "This will destroy the virtual machine '$imgName' and all data will be lost. Are you sure? [y/N]"; then
		rm "$img"
	fi
}

# Parse command
case $1 in
create)
	shift
	create "$@"
	;;
run)
	shift
	run "$@"
	;;
destroy)
	shift
	destroy "$@"
	;;
*)
	echo "Error: Unrecognized command: $1" >&2
	exit 1
	;;
esac