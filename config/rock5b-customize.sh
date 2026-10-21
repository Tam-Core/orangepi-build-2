#!/bin/bash
set -euo pipefail
[[ $3 == rock5b && $4 == no && $5 == arm64 ]]
# Remove upstream demonstration payloads from the OS image.
rm -f /usr/local/test.mp4 /usr/local/bin/watchdog_test
rm -f /usr/share/sounds/alsa/audio.wav /usr/share/sounds/alsa/mute.wav
# Keep the first login local and require replacement of public initial passwords.
chage -d 0 root
chage -d 0 orangepi
# Vendor firstrun restarts SSH; its optional account wizard must not override
# the fixed local-login policy. Keep the separate filesystem-resize service.
systemctl disable orangepi-firstrun.service orangepi-firstrun-config.service
systemctl mask orangepi-firstrun.service orangepi-firstrun-config.service
rm -f /root/.not_logged_in_yet
systemctl disable ssh.service ssh.socket
systemctl mask ssh.service ssh.socket
rm -f /etc/ssh/ssh_host_*
systemctl set-default multi-user.target
printf '%s\n' 'Radxa ROCK 5B — minimal Debian 13 ARM64' > /etc/issue
