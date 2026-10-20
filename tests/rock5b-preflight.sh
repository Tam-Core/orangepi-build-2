#!/usr/bin/env bash
# Static checks only. This does NOT prove that the microSD image boots.
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
board="$root/external/config/boards/rock5b.conf"
family="$root/external/config/sources/families/rockchip-rk3588.conf"
common="$root/external/config/sources/families/include/rockchip64_common.inc"

bash -n "$board" "$family" "$common" "$root/build.sh"
(
    source "$board"
    [[ "$BOARD_NAME" == "Radxa ROCK 5B (experimental)" ]]
    [[ "$BOARDFAMILY" == "rockchip-rk3588" ]]
    [[ "$BOOTCONFIG" == "rock-5b-rk3588_defconfig" ]]
    [[ "$KERNEL_TARGET" == "next" ]]
    [[ "$BOOT_FDT_FILE" == "rockchip/rk3588-rock-5b.dtb" ]]
    [[ "$BOOT_SCENARIO" == "spl-blobs" ]]
    [[ "$BOOT_SUPPORT_SPI" == "no" ]]
    [[ "$DISTRIB_TYPE_NEXT" == "trixie" ]]
)
grep -Fq "BOOTSOURCE='https://github.com/radxa/u-boot.git'" "$family"
grep -Fq "BOOTBRANCH='branch:stable-5.10-rock5'" "$family"
grep -Fq "BOOTDIR=\"\${SRC}/u-boot-radxa-rock5b\"" "$family"
grep -Fq 'if [[ $BOARD == rock5b ]]; then' "$common"
grep -Fq 'idbloader.img' "$common"

test -f "$root/external/config/desktop/trixie/environments/xfce/support"
test -f "$root/external/config/desktop/trixie/appgroups/office/packages"
test -f "$root/external/config/desktop/trixie/appgroups/rock5b-essentials/packages"
grep -qx 'libreoffice' "$root/external/config/desktop/trixie/appgroups/office/packages"
grep -qx 'keepassxc' "$root/external/config/desktop/trixie/appgroups/rock5b-essentials/packages"

printf '%s\n' 'PASS: Rock 5B configuration and Debian 13 package-group static checks'
printf '%s\n' 'NOT TESTED: U-Boot compilation, kernel compilation, image creation or real hardware boot'
