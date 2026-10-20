# Rock 5B hardware acceptance record

Hardware testing is outstanding. A successful CI build or image inspection does
not establish that this image boots on a physical Radxa ROCK 5B.

Record the image filename and SHA-256, source commit, board revision/RAM,
microSD model/capacity, power supply, display and attached USB devices. Preserve
the complete UART transcript and the commands/results below with the report.
The configured serial console is `ttyS2` at 1500000 baud; follow Radxa's board
documentation for the correct UART adapter, voltage and connections.

Use a dedicated microSD and keep known-good recovery media. Do not flash SPI,
eMMC or NVMe firmware. Establish from the boot log which bootloader and storage
device actually supplied the kernel; an existing SPI installation can affect
the observed boot path.

| Test | Required evidence | Result |
| --- | --- | --- |
| Cold boot | Full UART from power-on through a working login, with U-Boot, BL31 and kernel versions | NOT TESTED |
| Board identity | `tr -d '\0' </proc/device-tree/model`, `uname -a`, `/etc/os-release`, `dpkg --print-architecture` | NOT TESTED |
| Storage | `lsblk -f`, `findmnt /`, `dmesg` showing microSD and no I/O errors | NOT TESTED |
| Persistence | Create a harmless file, record its SHA-256, reboot and verify the same hash | NOT TESTED |
| Ethernet | Link, DHCP address, gateway reachability and DNS lookup | NOT TESTED |
| Display | HDMI console output at the connected display's supported mode | NOT TESTED |
| USB | Keyboard input and removable test-drive enumeration/read/write | NOT TESTED |
| Restart | Several clean reboots with UART logs and working network/storage afterwards | NOT TESTED |
| Shutdown | Clean filesystem shutdown and reliable subsequent cold boot | NOT TESTED |
| Stability | Sustained CPU/storage activity, temperatures and kernel error logs | NOT TESTED |

Do not claim XFCE, LibreOffice, KeePassXC or wallet/signer acceptance from the CLI
image. Desktop functional tests follow a verified CLI boot. Electrum SPV/Signer
still requires exact source/version selection, dependency and licence review,
ARM64 tests and chain-specific deterministic signing/verification vectors.

Before a production release, also audit default accounts/autologin, package
signatures, dependency provenance, firmware redistribution rights, source
availability and reproducibility. No real wallet secrets belong in test logs.
