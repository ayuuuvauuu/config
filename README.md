# Config & Notes

## Bluetooth
```bash
# enable
sudo rfkill unblock bluetooth
sudo systemctl start bluetooth

# disable auto-start
sudo systemctl disable bluetooth.service
```
### File transfer
- install `bluez-obex`
- start: `sudo systemctl start blueman-mechanism.service bluetooth.service`
- check obex: `ps aux | rg obe`

## Gaming
```bash
PROTON_USE_NTSYNC=1 PROTON_ENABLE_WAYLAND=1 -noeac -setfps 140 -triplebuffer -nonetworknext -high
```
Change TTL to 65 to trick ISP (not a hotspot):
```bash
# TODO: add command
```

## Sway / Wayland
put in `/etc/sway/config.d/`:
```
exec --no-startup-id dbus-update-activation-environment --systemd \
   WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway XDG_SESSION_DESKTOP=sway XDG_SESSION_TYPE=wayland
exec --no-startup-id systemctl --user start pipewire wireplumber xdg-desktop-portal xdg-desktop-portal-wlr
```
### Screen sharing
- https://bbs.archlinux.org/viewtopic.php?id=291201
- `screensy` https://screensy.marijn.it
### Recording
- use `gpu-screen-recorder-gtk`
- use `h264ify` for youtube hardware accel & less battery

## Packages
| Category | Packages |
|---|---|
| System | `btop`, `dysk`, `dua-cli`, `eza`, `fd`, `fzf`, `rg`, `zoxide`, `jq`, `tmux` |
| Editors | `nvim` (latest), `st` (suckless), `foot` |
| WM/DE | `sway`, `waybar`, `rofi`, `nitrogen` |
| Shell | `fish`, `lynx` |
| Fonts | `JetBrainsMono Nerd Font` (save in `~/.local/share/fonts` & `/usr/share/fonts/`, use `fc-list`) |
| Media | `vlc`, `GIMP` |
| Dev | `rust`, `gcc`, `clang`, `nodejs` (v20), `sccache`, `pomo` |
| Fun | `lavat`, `pipes.sh`, `cboansi`, `cmatrix`, `fastfetch`, `rain.sh` |

### Install Methods
```bash
# nodejs
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
sudo apt-get install -y nodejs

# pomodoro
sudo ln -sf /opt/pomodoro/pomo.sh /usr/local/bin/pomo
```

## Misc
- install `bleachbit` to clean old files
- `pip install i3ipc`
- install `gammastep`
- install waybar from my github
- set fish default term
- `astrortm`, `delta` (git pager), `so` (tui for stackoverflow)
- remove all `fish.tmp.*` from fish dir to clear temp env vars
- install `unp`
- font check: `fc-list`
- switch to g++ 12 if nvim errors
- add to `/etc/environment`: `EDITOR=nvim`

## Neovim Config
https://github.com/ayuuuvauuu/nvchad

## Fish Key Bindings
```bash
fzf_configure_bindings --help
```

---
# System Optimizations

## Power Saving

### Kernel Params
File: `/etc/default/limine` (reboot required)

| Param | What | Save |
|---|---|---|
| `nmi_watchdog=0` | stop watchdog that bites CPU every sec | ~0.5W |
| `i915.enable_psr=2` | panel self-refresh, redraw only changes | ~0.3W |
| `i915.enable_fbc=1` | compress framebuffer data | ~0.1W |
| `i915.enable_dc=4` | deep display C-states | ~0.1W |
| `iwlwifi.power_save=1` | wifi naps when idle | ~0.2W |
| `nvme_core.default_ps_max_latency_us=0` | NVMe deepest idle power state | ~0.3W |

### Intel LPMD
`/etc/intel_lpmd/intel_lpmd_config.xml`:
```xml
<PowersaverDef>1</PowersaverDef>
```

### TLP
File: `/etc/tlp.conf`
```
TLP_DISABLE_DEFAULTS=1
TLP_AUTO_SWITCH=1
TLP_PROFILE_AC=PRF
TLP_PROFILE_BAT=SAV

PCIE_ASPM_ON_AC=performance
PCIE_ASPM_ON_BAT=powersupersave
SOUND_POWER_SAVE_ON_AC=1
SOUND_POWER_SAVE_ON_BAT=1
SOUND_POWER_SAVE_CONTROLLER=Y

USB_AUTOSUSPEND=1
USB_DENYLIST="17ef:60a9"        # mouse at 3-2

DEVICES_TO_ENABLE_ON_AC="bluetooth wifi"
DEVICES_TO_DISABLE_ON_BAT="bluetooth"
```
Apply:
```bash
sudo systemctl enable --now tlp
tlp-stat -s   # status
tlp-stat -c   # config
```

### auto-cpufreq + ananicy-cpp
- CPU governor managed by auto-cpufreq (not TLP)
- ananicy-cpp for IO priority

### Sysctl
`/etc/sysctl.d/powersave.conf`:
```
kernel.nmi_watchdog = 0
```

### NVIDIA D3Cold
```bash
cat /sys/bus/pci/devices/0000:01:00.0/power_state
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status
```
GPU enters D3cold (~0W) when idle via RTD3.

### Dark Theme
System-wide dark theme for GTK + Qt.

**GTK 3/4** (`~/.config/gtk-3.0/settings.ini`, `~/.config/gtk-4.0/settings.ini`):
```ini
[Settings]
gtk-theme-name = Adwaita-dark
gtk-icon-theme-name = Adwaita
gtk-application-prefer-dark-theme = true
```

**Qt** — add to `/etc/environment`:
```
QT_QPA_PLATFORMTHEME=gtk3
GTK_THEME=Adwaita:dark
```
Requires `libqgtk3.so` (comes with qt6-base/qt5-base).

---
## Boot Optimization

### Baseline
```
Startup finished in 5.642s (firmware) + 748ms (loader) + 537ms (kernel) + 1.650s (initrd) + 4.003s (userspace) = 12.581s
```
**Expected after fixes:** ~8-9s

### mkinitcpio — initramfs
File: `/etc/mkinitcpio.conf`
```
MODULES=(nvme btrfs)
FILES=(/lib/firmware/i915/modified_vbt)
HOOKS=(base udev autodetect microcode modconf block resume filesystems)
COMPRESSION="cat"
```
| Change | Why | Save |
|---|---|---|
| `systemd` → `base udev` hook | busybox smaller than full systemd (~10MB→1MB) | ~200ms |
| Removed `keyboard`+`keymap` | no LUKS/rescue input needed | ~50ms |
| `MODULES=(nvme btrfs)` | early-load NVMe before udev | ordering |
| `COMPRESSION="cat"` (uncompressed) | NVMe reads ~3GB/s, no point decompressing | ~100ms |

Apply:
```bash
sudo mkinitcpio -P
```

> **⚠️ Warning:** `lsinitcpio -x` extracts all initramfs files (including busybox applets) to the current directory. If run from `/home/ayu/`, it creates a `bin/` directory with busybox symlinks (`ps`, `cat`, `chmod`, etc.). If your PATH contains bare `bin:`, these override system commands. Fix: `sudo rm -rf /home/ayu/bin`.

#### systemd vs busybox hook — tradeoffs

| Aspect | `systemd` hook | `base udev` (busybox) |
|---|---|---|
| Initramfs size | ~10MB | ~1MB |
| Boot time overhead | ~200ms | ~0ms |
| Disk decryption | LUKS2 tokens, TPM2, PIN, FIDO2 | Traditional passphrase only |
| Remote unlock | systemd-tty-ask-password-agent | No |
| `systemd-repart` | Supported | Not available |
| `systemd-homed` early mount | Supported | Not available |
| Early journald logs | Available in initrd | Not available |
| ZFS / complex volumes | Via systemd-importd/zpool | Via `zfs` hook |
| Microcode loading | Via systemd | Via `microcode` hook (same) |
| Resume from hibernate | systemd-hibernate-resume | systemd-hibernate-resume (same binary) |
| udev / device discovery | systemd-udevd | udev (same) |

**Bottom line:** For a standard NVMe + btrfs laptop with no LUKS or simple passphrase-only LUKS, busybox is strictly better (faster, smaller). Switch back to `systemd` if you add TPM2/FIDO2 disk unlock, systemd-homed, or systemd-repart.

### TPM — 3s delay fix
**Problem:** systemd waits 3s for /dev/tpm0 (TPM firmware init).

**Fix:** `tpm_tis.interrupts=0` in kernel cmdline → polling mode, skips slow interrupt init.

File: `/etc/default/limine` → `sudo limine-update`

### systemd-analyze blame (before fixes)
| Consumer | Time | Fix |
|---|---|---|
| TPM device | ~3.05s | `tpm_tis.interrupts=0` |
| nvidia-persistenced | ~859ms | Required |
| Serial ports | ~120ms | Minor |
| Other | ~250ms | — |

---
## Suspend & Hibernate

### Lid close — screen off only
File: `/etc/systemd/logind.conf`
```
HandleLidSwitch=ignore
```
Apply: `sudo systemctl restart systemd-logind`

### NVIDIA — skip VRAM dump (fast suspend)
File: `/etc/modprobe.d/nvidia.conf`
```
options nvidia NVreg_EnableS0ixPowerManagement=1 NVreg_PreserveVideoMemoryAllocations=0
```

### i915 — PSR/DC fix (was causing 20s eDP link training loop on resume)
Changed in kernel cmdline: `i915.enable_psr=0 i915.enable_dc=0`
(was `i915.enable_psr=2 i915.enable_dc=4`)

| Metric | Before (PSR on) | After (PSR off) |
|---|---|---|
| PSR aux errors/boot | 2 | 0 |
| Suspend time | ~30s | ~14s |
| Idle power | ~11W | ~13W |

### Hibernate swap device
Swap UUID: `89bc64d4-f652-4586-bb5a-35b6ffa13719` (`/dev/nvme0n1p6`)

Kernel cmdline includes `resume=UUID=...` for hibernation image detection.

### Silent resume (suppress cold-boot message)
The `systemd-hibernate-resume.service` prints "Unable to resume from device" on every cold boot. Two layers suppress it:

**Initramfs** — wraps the binary to redirect output:
File: `/etc/initcpio/install/silent-resume`
```bash
build() {
    mv "$BUILDROOT/usr/lib/systemd/systemd-hibernate-resume" \
       "$BUILDROOT/usr/lib/systemd/systemd-hibernate-resume.real"
    cat > "$BUILDROOT/usr/lib/systemd/systemd-hibernate-resume" << 'WRAPPER'
#!/bin/sh
exec /usr/lib/systemd/systemd-hibernate-resume.real "$@" >/dev/null 2>&1
WRAPPER
    chmod +x "$BUILDROOT/usr/lib/systemd/systemd-hibernate-resume"
}
```
Hook added to mkinitcpio.conf: `HOOKS=(... resume silent-resume filesystems)`

**Main system** — drop-in silences stdout/stderr:
File: `/etc/systemd/system/systemd-hibernate-resume.service.d/silent.conf`
```
[Service]
StandardOutput=null
StandardError=null
```

The resume check still runs — if a hibernation image exists, it resumes; if not, it exits silently.

---
## Shutdown

### nvidia-persistenced — 10s+ delay fix
**Problem:** nvidia-persistenced ignores SIGTERM during shutdown; systemd waits 90s default.

**Fix:** `TimeoutStopSec=3` via drop-in.

File: `/etc/systemd/system/nvidia-persistenced.service.d/override.conf`
```
[Service]
TimeoutStopSec=3
```

---
## Config File Reference

### Kernel cmdline template
`/etc/default/limine`:
```
ESP_PATH="/boot"
KERNEL_CMDLINE[default]+="nvidia-drm.modeset=1 quiet nowatchdog nmi_watchdog=0 i915.enable_psr=0 i915.enable_fbc=1 i915.enable_dc=0 iwlwifi.power_save=1 rw rootflags=subvol=/@ root=UUID=f7d828f3-6031-4f9b-a164-fed7f21a082b tpm_tis.interrupts=0 resume=UUID=89bc64d4-f652-4586-bb5a-35b6ffa13719 i915.vbt_firmware=i915/modified_vbt nvme_core.default_ps_max_latency_us=0"
BOOT_ORDER="*, *lts, *fallback, Snapshots"
```
Apply: `sudo limine-update`

### NVIDIA driver options
`/etc/modprobe.d/nvidia.conf`:
```
options nvidia-drm modeset=1 fbdev=1
options nvidia NVreg_UsePageAttributeTable=1 NVreg_InitializeSystemMemoryAllocations=0
options nvidia NVreg_DynamicPowerManagement=0x02
options nvidia NVreg_EnableS0ixPowerManagement=1 NVreg_PreserveVideoMemoryAllocations=0
```

### NVIDIA GPU runtime PM
`/etc/udev/rules.d/80-nvidia-pm.rules`:
```
ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="auto"
ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="auto"
ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="on"
ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="on"
```

### Active services
- `auto-cpufreq` — CPU governor (powersave on battery)
- `nvidia-powerd` — NVIDIA dynamic power management
- `nvidia-persistenced` — NVIDIA persistence daemon
- `tlp` — power management (AC/battery profiles)

### UPower override
`/etc/systemd/system/upower.service.d/override.conf`:
```
[Service]
Type=simple
```

---
## Battery Impact of Changes
| Change | Impact | Why |
|---|---|---|
| `systemd` → `base+udev` | None | Initrd only runs at boot |
| Removed `keyboard`+`keymap` | None | Initrd-only hooks |
| `COMPRESSION="cat"` | None | <10ms extra I/O on NVMe |
| `tpm_tis.interrupts=0` | Slightly positive | Fewer IRQs |
| `pcie_aspm=force` removed | Minimal | BIOS enables ASPM for working devices; TLP tunes policy |
| `nvme_core.default_ps_max_latency_us=0` | Positive | NVMe enters deepest idle power state |
| `TimeoutStopSec=3` services | None | Shutdown-only change |
