#!/bin/bash
set -euo pipefail
[[ $3 == rock5b && $4 == no && $5 == arm64 ]]
# Keep the first login local and require replacement of public initial passwords.
chage -d 0 root
chage -d 0 orangepi
systemctl disable ssh.service 2>/dev/null || true
systemctl disable ssh.socket 2>/dev/null || true
systemctl set-default multi-user.target
printf '%s\n' 'Radxa ROCK 5B — minimal Debian 13 ARM64' > /etc/issue
