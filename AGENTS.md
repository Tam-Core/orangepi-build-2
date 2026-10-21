# ROCK 5B minimal microSD OS

Deliver only a minimal Debian 13 ARM64 command-line operating system for Radxa
ROCK 5B. No desktop or optional applications. Work on rock5b-minimal-microsd;
leave upstream next unchanged. Preserve upstream compatibility and licences.
Never flash SPI, eMMC or NVMe. Build and inspect a microSD image and record
checksums and dependency provenance. Distinguish image verification from actual
physical-board boot testing. Run tests/rock5b-preflight.sh and
 tests/rock5b-effective-config.sh before pushing. Never claim hardware testing
without actual board evidence.
