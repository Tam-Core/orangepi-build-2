#!/usr/bin/env bash
# Disposable CI container only: exercise file-backed loop partition discovery.
set -euo pipefail
[[ $EUID == 0 && -f /.dockerenv ]]
[[ $(systemd-detect-virt --container) == docker ]]
source scripts/image-helpers.sh
display_alert() { printf '%s\n' "$*"; }
exit_with_error() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
CONTAINER_COMPAT=yes
mkdir -p output/debug
image=$(mktemp -p output/debug loop-preflight.XXXXXX)
loop=''
created_node=''
cleanup() {
    [[ -z $loop ]] || losetup -d "$loop"
    [[ -z $created_node ]] || rm -f -- "$created_node"
    rm -f -- "$image"
}
trap cleanup EXIT
truncate -s 64M "$image"
printf 'label: dos\nstart=2048,type=83\n' | sfdisk "$image"
loop=$(losetup --find --show --partscan "$image")
[[ -b ${loop}p1 ]] || created_node="${loop}p1"
check_loop_device "${loop}p1"
[[ -b ${loop}p1 ]]
lsblk -o NAME,TYPE,MAJ:MIN "$loop"
echo 'PASS: Docker detection and file-backed loop partition device discovery'
