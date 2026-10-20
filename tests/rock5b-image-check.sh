#!/usr/bin/env bash
# Inspect an image file without writing to the image or any physical device.
set -euo pipefail
[[ $# == 2 && $EUID == 0 ]] || { echo "Usage: sudo bash $0 IMAGE.img REPORT_DIRECTORY" >&2; exit 2; }
image=$(realpath "$1")
[[ -f $image && $image == *.img ]] || { echo 'Expected a regular .img file' >&2; exit 2; }
mkdir -p "$2"
report=$(realpath "$2")
scratch=$(mktemp -d)
loop=''
cleanup() {
    mountpoint -q "$scratch/root" && umount "$scratch/root"
    [[ -z $loop ]] || losetup -d "$loop"
    rm -rf -- "$scratch"
}
trap cleanup EXIT
exec > >(tee "$report/image-check.log") 2>&1

sha256sum "$image" > "$report/image.sha256"
sfdisk --json "$image" > "$report/partitions.json"
loop=$(losetup --find --show --read-only --partscan "$image")
udevadm settle
partition="${loop}p1"
[[ -b $partition ]]
[[ $(blkid -s TYPE -o value "$partition") == ext4 ]]
e2fsck -fn "$partition"
mkdir "$scratch/root"
mount -o ro,noload "$partition" "$scratch/root"
root="$scratch/root"

grep -Eq '^VERSION_ID="?13"?$' "$root/etc/os-release"
readelf -h "$root/usr/bin/bash" | tee "$report/userspace-elf.txt" | grep -q 'Machine:.*AArch64'
[[ $(od -An -tx1 -j56 -N4 "$root/boot/Image" | tr -d ' \n') == 41524d64 ]]
dumpimage -l "$root/boot/uInitrd" > "$report/initrd-header.txt"
test -s "$root/boot/boot.scr"
grep -qx 'fdtfile=rockchip/rk3588-rock-5b.dtb' "$root/boot/orangepiEnv.txt"
dtb="$root/boot/dtb/rockchip/rk3588-rock-5b.dtb"
fdtget -t s "$dtb" / compatible | tee "$report/dtb-compatible.txt" | grep -qw 'radxa,rock-5b'
test -d "$root/lib/modules"
find "$root/lib/modules" -mindepth 1 -maxdepth 1 -type d > "$report/kernel-module-versions.txt"
test -s "$report/kernel-module-versions.txt"

# Verify that the packaged bootloader bytes are actually present in the image.
mapfile -t loaders < <(find "$root/usr/lib" -type f -name idbloader.img)
[[ ${#loaders[@]} == 1 ]]
loader=${loaders[0]}
uboot="$(dirname "$loader")/u-boot.itb"
test -s "$loader"
test -s "$uboot"
dumpimage -l "$uboot" > "$report/uboot-fit.txt"
for entry in "$loader:32768" "$uboot:8388608"; do
    binary=${entry%:*}
    offset=${entry##*:}
    cmp -n "$(stat -c %s "$binary")" "$binary" "$image" 0 "$offset"
done
sha256sum "$loader" "$uboot" "$dtb" "$root/boot/Image" "$root/boot/uInitrd" > "$report/components.sha256"

# Export the full installed package inventory and account policy without hashes.
cp "$root/var/lib/dpkg/status" "$report/dpkg-status.txt"
awk -F: '{ print $1 ":" (($2 ~ /^[!*]/) ? "locked" : "password-enabled") }' \
    "$root/etc/shadow" > "$report/account-policy.txt"
printf '%s\n' 'PASS: partition, ext4, Debian 13, ARM64, kernel, initrd, Rock 5B DTB and embedded bootloader checks.'
printf '%s\n' 'NOT TESTED: physical boot, UART, power, Ethernet, HDMI, USB, storage persistence, reboot or shutdown.'
