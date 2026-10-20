# Rock 5B firmware notices

Include these notices with any distributed experimental image bundle.

- `rockchip-rkbin.txt`: copied from `orangepi-xunlong/rk-rootfs-build`, branch `rkbin`, `LICENSE.TXT` (Git blob `07488283c5a5937bd109164e5ca9c6f07b4b0dc9`). The board uses Rockchip DDR firmware embedded in `idbloader.img`; this licence does not replace the licences of U-Boot or Linux.
- `tfa-v2.13.0-license.rst`: copied from `ARM-software/arm-trusted-firmware`, tag `v2.13.0`, `docs/license.rst`. The included mainline BL31 binary is described in `external/packages/blobs/rockchip/rk35/README.bl31`. Individual source-file notices also apply.

The release must record the actual kernel, U-Boot and rkbin revisions and component hashes. Preserve corresponding source access, U-Boot/Linux notices, and the Debian package copyright files inside the image. These copied notices alone do not establish completion of the full licence/provenance acceptance gate.
