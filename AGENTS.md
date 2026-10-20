# Codex / development instructions — experimental Rock 5B port

Scope: `feature/rock5b-debian13-bringup`, initially draft PR #1.

## Goal
Produce a verified Debian 13 (Trixie) ARM64 microSD image for **Radxa ROCK 5B**
using the Orange Pi build framework. Preserve compatibility with all existing
Orange Pi targets. The first milestone is a working **CLI boot**, then XFCE,
LibreOffice, KeePassXC, and finally the validated Electrum SPV/Signer packages.

## Non-negotiable constraints
- Do not alter or merge `next` directly. Commit changes on this feature branch.
- No SPI NOR, eMMC or NVMe firmware flashing; microSD image files only.
- No secrets, wallet seed phrases, real private keys or WIFs in code or CI logs.
- Do not install arbitrary wallet code without verifying exact upstream source,
  licence, pinning dependencies, ARM64 compatibility and deterministic tests.
- Preserve upstream licences, copyright, third-party notices and attribution.
- Do not claim a bootable release unless all image-build tests pass; never claim
  physical Rock 5B boot unless actual hardware evidence exists.
- Do not solve Python dependency conflicts by downgrading Debian's system Python;
  use a separately pinned, isolated environment if required.
- Skip Orange Pi-only BSP/firmware modifications on the Radxa target.

## Source references
- `external/config/boards/rock5b.conf`
- `external/config/sources/families/rockchip-rk3588.conf`
- `external/config/sources/families/include/rockchip64_common.inc`
- `docs/rock5b-bringup.md` for build stages and acceptance criteria.
- U-Boot: Radxa `stable-5.10-rock5` `rock-5b-rk3588_defconfig`
- Kernel: Orange Pi `orange-pi-6.18-rk35xx`, Rock 5B DTB.

## Workflow
1. Review this PR's changes for actual API/SDK compatibility.
2. Execute `bash tests/rock5b-preflight.sh`.
3. Obtain Ubuntu 22.04 Linux build environment with sufficient storage and
   supported cross-compiler. Run U-Boot and kernel builds with logs.
4. Produce and inspect a CLI microSD image; record SHA-256 and component hashes.
5. If blocked, report exact error and fix it in this PR. Do not fake successful
   builds or substitute a prebuilt Orange Pi 5 Plus image.
6. After *actual* physical boot evidence, add XFCE and office/password tooling.
7. Test Electrum SPV and Signer independently using only public deterministic
   test vectors, including chain-specific signing and transaction verification.
8. Complete licensing, image hardening and provenance checks before release.

## Test status vocabulary
- **Source preflight passed:** bash syntax and declared configuration only.
- **Image built:** generated and inspected disk image; boot not implied.
- **Hardware tested:** physical Rock 5B logs and peripheral test evidence.
- **Release-ready:** all acceptance gates complete.

If runtime tooling is absent, return an exact blocked status and record the
unperformed tests; do not invent a working release.
