#!/usr/bin/env bash
# Run after a fresh compilation; fail closed if corresponding sources are absent.
set -euo pipefail
destination=output/release-sources
mkdir -p "$destination/licenses" "$destination/sources"
cp -a docs/licenses/. "$destination/licenses/"
git rev-parse HEAD > "$destination/SOURCE-REVISION.txt"
git archive HEAD | xz -T2 > "$destination/sources/image-builder.tar.xz"
mapfile -t kernels < <(find kernel -mindepth 1 -maxdepth 1 -type d)
mapfile -t uboots < <(find u-boot-radxa-rock5b -mindepth 1 -maxdepth 1 -type d)
[[ ${#kernels[@]} == 1 && ${#uboots[@]} == 1 ]]
kernel=${kernels[0]}
uboot=${uboots[0]}
mapfile -t packages < <(find output/debs -name 'linux-source-*.deb')
[[ ${#packages[@]} == 1 ]]
dpkg-deb -x "${packages[0]}" "$destination/sources/linux-source-package"
cp "$kernel/COPYING" "$destination/licenses/Linux-COPYING"
cp -a "$kernel/LICENSES" "$destination/licenses/Linux-LICENSES"
cp -a "$uboot/Licenses" "$destination/licenses/U-Boot-Licenses"
cp "$uboot/.config" "$destination/sources/u-boot.config"
tar -C "$uboot" --exclude=.git -c . | xz -T2 > "$destination/sources/u-boot-corresponding-source.tar.xz"
git clone --depth 1 --branch v2.13.0 https://github.com/ARM-software/arm-trusted-firmware.git output/tfa-source
git -C output/tfa-source archive HEAD | xz -T2 > "$destination/sources/tfa-v2.13.0.tar.xz"
cp external/packages/blobs/rockchip/rk35/README.bl31 "$destination/licenses/TF-A-BUILD.txt"
cp external/cache/sources/rkbin-tools/LICENSE.TXT "$destination/licenses/rockchip-rkbin.txt"
{
    for directory in "$kernel" "$uboot" external/cache/sources/rkbin-tools output/tfa-source; do
        printf '%s %s %s\n' "$directory" "$(git -c safe.directory='*' -C "$directory" remote get-url origin)" "$(git -c safe.directory='*' -C "$directory" rev-parse HEAD)"
    done
} > "$destination/COMPONENT-REVISIONS.txt"
sha256sum external/packages/blobs/rockchip/rk35/rk3588_bl31_tfa_v2.13.0.elf \
    external/cache/sources/rkbin-tools/rk35/rk3588_ddr_lp4_2112MHz_lp5_2400MHz_v1.24_support_dmi_behavior_mode_1.bin \
    > "$destination/FIRMWARE-SHA256SUMS.txt"
find output/debs -name '*.deb' -exec sha256sum {} + > "$destination/COMPILED-PACKAGES-SHA256SUMS.txt"
cat > "$destination/licenses/SOURCE-INFORMATION.md" <<'EOF'
This bundle includes the patched Linux source and configuration in sources/
linux-source-package/usr/src, the complete U-Boot build tree, the image builder
at SOURCE-REVISION.txt, and upstream TF-A v2.13.0 source. The image builder's
scripts/compilation.sh and external/config contain the build commands, patches,
cross-compiler selection and board configuration. COMPONENT-REVISIONS.txt records
the actual repositories/revisions, and the build evidence records compiler versions.
The U-Boot source archive also contains generated build outputs; .config is included.

Rockchip's proprietary DDR binary is embedded unchanged in idbloader.img; its
redistribution licence is rockchip-rkbin.txt. TF-A-BUILD.txt describes the supplied
BL31 binary and its upstream source/toolchain. Firmware hashes are recorded.

The root filesystem is Debian 13. Debian package notices remain in
/usr/share/doc/*/copyright and /usr/share/common-licenses inside the image.
The onboard Ethernet firmware comes from Debian firmware-realtek; its licence is
also exported alongside this file. verification/dpkg-status.txt identifies exact
installed package versions and Source fields. Corresponding Debian source packages
are available from https://deb.debian.org/debian/pool/ and
https://snapshot.debian.org/ (select the exact Source version, or package version
when Source is absent). Debian package licences are not replaced by this notice.

No physical board boot or peripheral validation has been performed.
EOF
find "$destination/sources" -name '*.xz' -exec xz -t {} +
