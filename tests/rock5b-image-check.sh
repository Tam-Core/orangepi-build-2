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
grep -qx 'ID=debian' "$root/etc/os-release"
[[ $(chroot "$root" dpkg --print-architecture) == arm64 ]]
cp "$root/etc/os-release" "$report/os-release.txt"
readelf -h "$root/usr/bin/bash" | tee "$report/userspace-elf.txt" | grep -q 'Machine:.*AArch64'
[[ $(od -An -tx1 -j56 -N4 "$root/boot/Image" | tr -d ' \n') == 41524d64 ]]
dumpimage -l "$root/boot/uInitrd" > "$report/initrd-header.txt"
dumpimage -T ramdisk -p 0 -o "$scratch/initrd" "$root/boot/uInitrd"
lsinitramfs "$scratch/initrd" > "$report/initrd-contents.txt"
test -s "$root/boot/boot.scr"
grep -qx 'fdtfile=rockchip/rk3588-rock-5b.dtb' "$root/boot/orangepiEnv.txt"
dtb="$root/boot/dtb/rockchip/rk3588-rock-5b.dtb"
fdtget -t s "$dtb" / compatible | tee "$report/dtb-compatible.txt" | grep -qw 'radxa,rock-5b'
test -d "$root/lib/modules"
find "$root/lib/modules" -mindepth 1 -maxdepth 1 -type d > "$report/kernel-module-versions.txt"
test -s "$report/kernel-module-versions.txt"
mapfile -t versions < <(find "$root/lib/modules" -mindepth 1 -maxdepth 1 -type d -printf '%f\n')
[[ ${#versions[@]} == 1 ]]
grep -Fq "lib/modules/${versions[0]}" "$report/initrd-contents.txt"
grep -qx "rootdev=UUID=$(blkid -s UUID -o value "$partition")" "$root/boot/orangepiEnv.txt"

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
    start=$(lsblk -nr -o START "$partition" | tr -d ' ')
    (( offset + $(stat -c %s "$binary") <= start * 512 ))
    cmp -n "$(stat -c %s "$binary")" "$binary" "$image" 0 "$offset"
done
sha256sum "$loader" "$uboot" "$dtb" "$root/boot/Image" "$root/boot/uInitrd" > "$report/components.sha256"

# Reject optional application payloads; inspect the installed package inventory.
awk 'BEGIN { RS=""; FS="\n" } /Status: install ok installed/ {
    for (i=1; i<=NF; i++) if ($i ~ /^Package: /) print substr($i,10)
}' "$root/var/lib/dpkg/status" | sort > "$report/installed-packages.txt"
if grep -E '^(libreoffice.*|keepassxc|electrum.*|xfce4.*|lightdm|gdm3|qrencode|zbar-tools|mc|htop|nano|jq|figlet|toilet|python3-dev|libpython3-dev|python3.13-venv|network-manager-openvpn|iozone3|lm-sensors|lsof|sysstat|i2c-tools|wireless-tools|smartmontools|fping|nocache|can-utils|orangepi-firmware|orangepi-zsh|orangepi-config)$' "$report/installed-packages.txt"; then
    echo 'FAIL: optional applications found in minimal image' >&2
    exit 1
fi
test ! -e "$root/usr/local/bin/watchdog_test"
test ! -e "$root/usr/local/test.mp4"
for package in sudo systemd openssh-server network-manager firmware-realtek; do
    grep -qx "$package" "$report/installed-packages.txt"
done
python3 - "$root" <<'PY'
import crypt, pathlib, sys
root = pathlib.Path(sys.argv[1])
accounts = {p[0]: p for line in (root/'etc/shadow').read_text().splitlines() if (p := line.split(':'))}
for name in ('root', 'orangepi'):
    entry = accounts[name]
    assert entry[2] == '0', f'{name} must change password'
    assert crypt.crypt('orangepi', entry[1]) == entry[1], f'{name} initial password mismatch'
for name, entry in accounts.items():
    assert entry[1], f'{name} has an empty password'
    assert name in ('root', 'orangepi') or entry[1].startswith(('!', '*')), f'unexpected login: {name}'
passwd = [line.split(':') for line in (root/'etc/passwd').read_text().splitlines()]
assert [p[0] for p in passwd if p[2] == '0'] == ['root']
assert [p[0] for p in passwd if 1000 <= int(p[2]) < 65534] == ['orangepi']
assert not (root/'root/.not_logged_in_yet').exists()
for path in (root/'etc/systemd/system').rglob('*'):
    if path.is_file() and not path.is_symlink():
        assert '--autologin' not in path.read_text(errors='replace'), f'autologin: {path}'
PY
for unit in ssh.service ssh.socket orangepi-firstrun.service orangepi-firstrun-config.service orangepi-hardware-monitor.service; do
    [[ $(readlink "$root/etc/systemd/system/$unit") == /dev/null ]]
done
[[ $(readlink "$root/etc/systemd/system/default.target") == /usr/lib/systemd/system/multi-user.target ]]
! find "$root/etc/ssh" -name 'ssh_host_*' | grep -q .
mkdir -p "$report/licenses"
cp -a "$root/usr/share/doc/firmware-realtek/copyright" "$report/licenses/firmware-realtek.txt"
cp -a "$root/usr/share/common-licenses" "$report/licenses/debian-common-licenses"
# Export the full installed package inventory and account policy without hashes.
cp "$root/var/lib/dpkg/status" "$report/dpkg-status.txt"
awk -F: '{ print $1 ":" (($2 ~ /^[!*]/) ? "locked" : "password-enabled") }' \
    "$root/etc/shadow" > "$report/account-policy.txt"
printf '%s\n' 'PASS: partition, ext4, Debian 13, ARM64, kernel, initrd, Rock 5B DTB and embedded bootloader checks.'
printf '%s\n' 'NOT TESTED: physical boot, UART, power, Ethernet, HDMI, USB, storage persistence, reboot or shutdown.'
