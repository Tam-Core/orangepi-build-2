#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../scripts/package-lists.sh"
[[ $(exclude_packages 'keep jq lsof i2c-tools python3-dev tail' 'jq lsof i2c-tools python3-dev') == 'keep tail' ]]
[[ $(exclude_packages 'python3.13-venv python3X13-venv mesa-utils mesa-utils-extra' 'python3.13-venv mesa-utils') == 'python3X13-venv mesa-utils-extra' ]]
[[ $(exclude_packages $'jq\n\tlsof jq' 'jq lsof jq') == '' ]]
[[ $(exclude_packages 'ethtool can-utils' 'can-utils') == ethtool ]]
[[ $(exclude_packages 'keep keep' '') == 'keep keep' ]]
echo 'PASS: adjacent, literal, duplicate and family package exclusions'
