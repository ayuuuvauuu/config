# AGENTS.md — Home Config

## Repo structure

Git repo `git@github.com:ayuuuvauuu/config.git` tracking a curated allowlist of
dotfiles. The `.gitignore` uses `*` + `!` pattern — **anything new you want tracked
must be added to `.gitignore` with a `!` rule**.

Only 616 files tracked (out of full home dir). System configs in `/etc/` are **not
tracked** in git — document any changes in `README.md` and back up manually.

## Key docs

- **`README.md`** (785 lines) — single source of truth for system config, power
  saving, boot optimization, NVIDIA, udev, TLP, LPMD, suspend/hibernate, and fixes
- `battery-report.md`, `suspend-and-hibernate-fix.md` — supplementary

## Config locations

| Scope | Path | Tracked? |
|---|---|---|
| User dotfiles | `~/.config/*` | Selected dirs (see `.gitignore`) |
| Shell/scripts | `~/.local/bin/` | Yes (all) |
| System config | `/etc/` (tlp, udev, modprobe, sysctl, mkinitcpio, systemd) | **No** |
| LPMD config | `/etc/intel_lpmd/intel_lpmd_config.xml` | No, `chattr +i` protected |

## System quirks & gotchas

- **Dead webcam** (`30c9:0069` on `usb3-port6`): hardware failure — `Cannot enable.`
  adds ~3s to kernel boot. No software fix. Ribbon cable likely loose at display end.
  Mitigated via initramfs hook (`disable-webcam`) + udev rule — see README.
- **Udev RUN key bug**: systemd-udevd >= v255 treats `$` in `RUN+=` as substitution.
  Inline shell scripts with `$f` / `$d` fail silently. Use standalone scripts
  (e.g. `/usr/local/bin/usb-power-switch`) instead. See README § "USB autosuspend".
- **`intel_lpmd_control`**: custom tool, not part of standard intel_lpmd package.
  Usage: `intel_lpmd_control OFF|AUTO`.
- **`chattr +i`** on `/etc/intel_lpmd/intel_lpmd_config.xml` — `pacman -Syu` resets it
  otherwise. `--overwrite` flag needed on updates.
- **OpenCode skills**: `.opencode/skills/` has openspec skills (explore, propose,
  apply-change, archive-change, sync-specs).

## Commands

| Task | Command |
|---|---|
| Rebuild initramfs | `sudo mkinitcpio -P` |
| Reload udev rules | `sudo udevadm control --reload-rules` |
| Test udev rule match | `sudo udevadm test /sys/class/power_supply/ADP1 2>&1 \| grep -E 'rule\|Invalid'` |
| Update LPMD config | edit `/etc/intel_lpmd/intel_lpmd_config.xml` (+ `chattr +i` after) |
| Boot analysis | `systemd-analyze blame`, `systemd-analyze critical-chain` |
| Verify NVIDIA PM | `cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status` |
| USB vendor:product | `lsusb` or `usb-list` (custom script in `~/.local/bin/`) |
| Apply kernel cmdline | edit `/etc/default/limine` then `sudo limine-update` |

Skills provide specialized instructions and workflows for specific tasks.
Use the skill tool to load a skill when a task matches its description.
