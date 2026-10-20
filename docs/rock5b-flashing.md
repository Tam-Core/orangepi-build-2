# ROCK 5B minimal Debian 13 ARM64 microSD image

This image contains the base command-line OS and system/networking utilities.
No desktop, office suite, password manager or wallet applications are selected.
Image inspection does not establish physical ROCK 5B boot or peripheral support.

Download the rock5b-debian13-cli-image artifact from the successful GitHub Actions
run, unzip the artifact, and verify the downloaded .img.xz against SHA256SUMS
(`sha256sum --ignore-missing -c SHA256SUMS`). Use balenaEtcher to select the .img.xz,
select a dedicated microSD card of at least 16 GB, and flash with verification.
This erases that card. Do not select another drive. Power off the ROCK 5B, insert
the card, connect HDMI, a USB keyboard and Ethernet, then apply suitable power.
No SPI, eMMC or NVMe firmware flashing is part of this procedure.

Initial local console login: orangepi / orangepi (root / orangepi is also
available). Password change is required at first login. SSH starts disabled;
after changing passwords, enable it only if wanted with
`sudo systemctl enable --now ssh`. There is no graphical desktop.

If HDMI stays blank, capture the board's debug UART at 1500000 baud using the
correct Radxa-documented voltage and wiring. Existing SPI/eMMC bootloaders can
change boot selection; do not erase or flash them as troubleshooting here.
Record the image checksum, UART log and results in rock5b-hardware-test.md.
Physical boot, Ethernet, HDMI, USB, persistence, reboot and shutdown remain
unverified until tested on a ROCK 5B.
