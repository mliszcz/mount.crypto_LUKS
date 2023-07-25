#!/bin/sh

cleanup()
{
  set +eu  # We do not want any failures in the cleanup routine.
  printf "\033[1;33m==== CLEAN UP ====\033[0m\n"
  umount -i "$tmpd/mnt"
  [ -f "/dev/mapper/$init_mapper" ] && cryptsetup close "$init_mapper"
  [ -f "/dev/mapper/$real_mapper" ] && cryptsetup close "$real_mapper"
  [ -f "$loopdev" ] && losetup -d "$loopdev"
  [ -d "$tmpd" ] && rm -rf "$tmpd"
}

trap cleanup EXIT

set -e
set -u
set -v

printf "\033[1;33m==== SET UP ====\033[0m\n"

tmpd="$(mktemp -d --tmpdir 'mount.crypto_LUKS.XXXXXX')"

disk="$tmpd/disk.img"
keyfile="$tmpd/keyfile"
init_mapper="$(mktemp -u 'mount.crypto_LUKS.XXXXXX')"

echo secret > "$keyfile"

fallocate -l 30M "$disk"  # 10M is too small for LUKS with default parameters.
cryptsetup -q luksFormat --iter-time 100 "$disk" "$keyfile"
cryptsetup luksOpen --key-file="$keyfile" "$disk" "$init_mapper"
mkfs.ext4 -q "/dev/mapper/$init_mapper"

mount --mkdir "/dev/mapper/$init_mapper" "$tmpd/mnt"

content="$(date)"  # Some data for comparison after decryption with helper.
echo "$content" > "$tmpd/mnt/file"

umount "$tmpd/mnt"
cryptsetup close "$init_mapper" 

printf "\033[1;33m==== TEST ====\033[0m\n"

loopdev="$(losetup --show --find "$disk")"
real_mapper="$(echo "$loopdev" | tr / _)"  # Must match the implementation.

mount --mkdir -o "cryptsetup=--key-file=$keyfile" "$loopdev" "$tmpd/mnt"

(set -x; test "$content" == "$(cat "$tmpd/mnt/file")")

umount "$tmpd/mnt"

(set -x; test ! -f "/dev/mapper/$real_mapper")

losetup -d "$loopdev"
