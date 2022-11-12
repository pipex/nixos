#!/bin/sh

set -e

[ -f "$stdenv/setup" ] && . $stdenv/setup

mkdir -p $out/bin
envsubst '$qemu,$iso' <$src >"$out/bin/nixos-machine"
chmod 755 "$out/bin/nixos-machine"
