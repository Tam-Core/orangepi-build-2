#!/bin/bash
set -euo pipefail
[[ $3 == rock5b && $4 == no && $5 == arm64 ]]
# Remove upstream demonstration payloads from the OS image.
rm -f /usr/local/test.mp4 /usr/local/bin/watchdog_test
rm -f /usr/share/sounds/alsa/audio.wav /usr/share/sounds/alsa/mute.wav
# Keep the first login local and require replacement of public initial passwords.
chage -d 0 root
chage -d 0 orangepi
systemctl disable ssh.service 2>/dev/null || true
systemctl disable ssh.socket 2>/dev/null || true
systemctl set-default multi-user.target
printf '%s\n' 'Radxa ROCK 5B — minimal Debian 13 ARM64' > /etc/issue
