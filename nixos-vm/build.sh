#!/bin/sh

set -e

[ -f "$stdenv/setup" ] && . $stdenv/setup

mkdir -p $out/bin
envsubst '$qemu,$iso' <$src >"$out/bin/nixos-vm"
chmod 755 "$out/bin/nixos-vm"
