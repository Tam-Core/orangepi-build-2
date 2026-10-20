# Experimental Radxa ROCK 5B port — Debian 13 ARM64

**Status: source-only bring-up. No bootable image or on-board test has been verified.**

This branch is based on Orange Pi's `next` source. It adds a Rock 5B target,
selects the documented Radxa vendor U-Boot configuration, reuses the
Orange Pi RK3588 Linux 6.18 kernel family, and supplies an XFCE/office/password
manager package selection. It must not be merged into `next` or released as
wallet-ready until all gates below pass.

## Targets and provenance

- Board: Radxa ROCK 5B, Rockchip RK3588, AArch64.
- Debian: 13 / Trixie.
- Kernel: Orange Pi `orange-pi-6.18-rk35xx` (`BRANCH=next`).
- Device tree: `rockchip/rk3588-rock-5b.dtb` (verified in that kernel source).
- U-Boot: `https://github.com/radxa/u-boot.git`, `stable-5.10-rock5`,
  `rock-5b-rk3588_defconfig` (verified source file exists).
- Boot media: microSD. **Do not change or flash the board's SPI NOR firmware.**
- Repo at start: `orangepi-xunlong/orangepi-build`, `next`,
  commit `a95129bf30ea11886cc35f08ebb3e69695a26656`.

Reference:
- https://wiki.radxa.com/Rock5/guide/build-u-boot-on-5b
- https://github.com/radxa/u-boot/tree/stable-5.10-rock5
- https://github.com/orangepi-xunlong/linux-orangepi/tree/orange-pi-6.18-rk35xx

This is *not* a validated combination of kernel, U-Boot and firmware. The
Rockchip DDR/BL31 files and any vendor packages must undergo redistribution
licence and provenance review before a public release.

## Safe initial build procedure

1. Use a supported, isolated Ubuntu 22.04 Linux build machine with suitable
   free disk space. Do not use a wallet containing real keys for builds.
2. Check out `feature/rock5b-debian13-bringup`. Keep upstream `next` untouched.
3. Run `bash tests/rock5b-preflight.sh` to check the source layout.
4. Follow the Orange Pi build prerequisites and configuration instructions.
   Be aware the upstream build launcher can switch branches automatically;
   confirm its `LIB_TAG` setting retains the experimental branch before running.
5. First generate a **CLI** image (no desktop), targeting
   `BOARD=rock5b BRANCH=next RELEASE=trixie BUILD_DESKTOP=no`.
   Keep kernel configuration non-interactive for a reproducible first test.
6. Preserve full build logs and record hashes of any resulting `.img`.
   A successful compile does not prove that the board will boot.

After a CLI image has been built and **physically** booted, use
`BUILD_DESKTOP=yes DESKTOP_ENVIRONMENT=xfce`
`DESKTOP_ENVIRONMENT_CONFIG_NAME=config_base`, and select appgroups
`office` and `rock5b-essentials`. These package groups request LibreOffice,
KeePassXC, QR-code tools, Python and supporting utilities.

For the first flash, select the microSD device by verified model and capacity.
Do not write a bootloader to SPI, eMMC, or NVMe. Keep a known-good Rock 5B
microSD image on separate media for recovery.

## Excluded from the first bring-up

- Electrum SPV / Signer: source repository, supported Python version,
  ARM64 dependencies, chain-specific transaction handling and test vectors
  must be verified independently before installation.
- Rebranding/default account and autologin hardening.
- USB QR signer workflow, key storage and cold/offline security guarantees.
- Hardware-accelerated GPU/VPU or Orange Pi-specific firmware features.

The Rock 5B board selection skips Orange Pi-specific BSP desktop hooks rather
than installing Orange Pi USB/GPIO services, firmware and Shanghai timezone
settings on a Radxa board. This may require additional Radxa-specific
functionality later.

## Required acceptance gates

1. **Static source:** `bash -n` and source preflight pass.
2. **Build:** U-Boot, kernel+DTB, Debian root filesystem and complete image
   build succeed without undocumented downloads, missing binaries or patches.
3. **Boot:** Rock 5B cold-boots the microSD; preserve UART log. No SPI flashing.
4. **Peripherals:** Ethernet, USB keyboard, display, storage, poweroff and reboot.
5. **Persistence:** Reboot preserves a harmless test file on microSD.
6. **Desktop:** XFCE launches, LibreOffice and KeePassXC open normally.
7. **Security:** No unknown default credentials/autologin; updates and package
   signatures verified; component licences and firmware redistribution audited.
8. **Wallets:** Only public test vectors, deterministic keys and disposable
   funds; signing and verification tested per chain; no production secrets.
9. **Release:** Include source revision, dependency inventory, SHA-256 hashes,
   reproducibility notes and physical-board test evidence.

**No release tag is justified until these gates are met.**
