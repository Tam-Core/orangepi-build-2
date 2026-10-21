#!/usr/bin/env bash
# Exercise family configuration, rather than just matching source strings.
set -eo pipefail
SRC=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
EXTER="$SRC/external"
enable_extension() { :; }
exit_with_error() { printf '%s\n' "$*" >&2; exit 1; }

check_board() (
    BOARD=$1
    BRANCH=next
    RELEASE=trixie
    # Upstream configuration uses false conditionals as normal defaults.
    set +e
    source "$EXTER/config/boards/$BOARD.conf"
    source "$EXTER/config/sources/families/rockchip-rk3588.conf"
    source "$EXTER/config/sources/arm64.conf"
    set -e
    if [[ $BOARD == rock5b ]]; then
        [[ $BOOTSOURCE == https://github.com/radxa/u-boot.git ]]
        [[ $BOOTBRANCH == branch:stable-5.10-rock5 ]]
        [[ $BOOTCONFIG == rock-5b-rk3588_defconfig ]]
        [[ $BOOTDIR == "$SRC/u-boot-radxa-rock5b" ]]
        [[ $BOOT_SUPPORT_SPI == no ]]
        [[ $UBOOT_TARGET_MAP != *rkspi_loader.img* ]]
        [[ $UBOOT_TARGET_MAP == *idbloader.img*u-boot.itb* ]]
        [[ $BOOT_FDT_FILE == rockchip/rk3588-rock-5b.dtb ]]
        # Both hooks must return without installing Orange Pi packages.
        family_tweaks_bsp
        family_tweaks_s
    else
        [[ $BOOTSOURCE == https://github.com/orangepi-xunlong/u-boot-orangepi.git ]]
        [[ $BOOTBRANCH == branch:v2017.09-rk3588 ]]
        [[ $BOOTCONFIG != rock-5b-rk3588_defconfig ]]
    fi
    [[ $KERNELBRANCH == branch:orange-pi-6.18-rk35xx ]]
    [[ $ARCH == arm64 ]]
)
check_board rock5b
check_board orangepi5plus
if (
    BOARD=rock5b BRANCH=legacy RELEASE=trixie
    source "$EXTER/config/boards/rock5b.conf"
    source "$EXTER/config/sources/families/rockchip-rk3588.conf"
); then
    echo 'FAIL: unsupported Rock 5B kernel branch was accepted' >&2
    exit 1
fi
echo 'PASS: effective Rock 5B config, unsupported-branch rejection and Orange Pi 5 Plus regression checks'
