# Config & Notes

add tun2socks in local/bin or modify script to use systemwide one
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

### Intel LPMD — quick reference
Full LPMD config and explanation in the [Intel LPMD section](#intel-lpmd--p-core-parking-on-battery-only) below.

> **⚠️ System updates overwrite LPMD config.** `pacman -Syu` replaces `/etc/intel_lpmd/intel_lpmd_config.xml` with package defaults, resetting thresholds and hysteresis. To prevent:
> ```bash
> sudo chattr +i /etc/intel_lpmd/intel_lpmd_config.xml   # immutable
> sudo pacman -Syu --overwrite /etc/intel_lpmd/intel_lpmd_config.xml   # or preserve on update
> ```

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

USB_AUTOSUSPEND=0               # udev rules handle USB
```
**USB note:** `USB_AUTOSUSPEND=0` lets udev rules handle AC vs battery behavior.
See "USB autosuspend — udev rules" below.

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
**Current (after all fixes):** `5.516s (firmware) + 1.054s (loader) + 1.111s (kernel+initrd) + 3.160s (userspace) = 10.843s`
graphical.target reached after 2.267s in userspace.
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
| nvidia-persistenced | ~859ms | Delayed off critical chain (below) |
| systemd-userdbd | ~995ms | Masked (below) |
| Serial ports | ~120ms | Minor |
| Other | ~250ms | — |

### Userspace — unnecessary services removed

**systemd-userdbd** — Dynamic user/group database for systemd-homed. On a standard
laptop with `/etc/passwd`, it's dead code (~995ms at boot).

```bash
sudo systemctl mask systemd-userdbd.service systemd-userdbd.socket
```

**lvm2-monitor** — LVM event monitoring daemon. Useless on btrfs (~107ms).

```bash
sudo systemctl mask lvm2-monitor.service
```

### Userspace — nvidia-persistenced off critical chain

nvidia-persistenced.service blocks `multi-user.target` (~791ms) because systemd
automatically adds `Before=multi-user.target` for services `WantedBy=multi-user.target`.

**Fix:** Drop-in removes default dependencies:

File: `/etc/systemd/system/nvidia-persistenced.service.d/delay-boot.conf`
```ini
[Unit]
DefaultDependencies=no
After=sysinit.target basic.target systemd-journald.socket
Before=shutdown.target
```

Effect: service still starts (via existing `WantedBy=multi-user.target` symlink), but
doesn't block reaching multi-user.target. ~791ms comes off the critical chain.

**NVIDIA impact:** No effect on GPU power management, suspend/resume, or driver
functionality. nvidia-suspend/resume/hibernate/powerd services have no dependency
on nvidia-persistenced. Only observable difference: first CUDA/GL call after login
may have a tiny mode-switch delay if initiated immediately (<1s window) — negligible
in practice since display manager + login takes longer than that.

**Verification:**
```bash
systemctl show -p Before,After,DefaultDependencies nvidia-persistenced.service
# Before=shutdown.target
# After=basic.target systemd-journald.socket system.slice sysinit.target
# DefaultDependencies=no
```

---
## CPU & Power Management

### Intel LPMD — P-core parking on battery only

**Source:** [Intel LPMD GitHub](https://github.com/intel/intel-lpmd)

The i5-12450H has 4 P-cores (with HT = 8 threads) + 4 E-cores. `intel_lpmd` parks
P-cores (restricts cgroup v2 cpuset) when on battery and CPU load is low — work
runs exclusively on E-cores. When util exceeds the exit threshold, P-cores come
back online (added back to cgroup cpuset).

**No impact on AC/gaming:** `PerformanceDef=-1` keeps LPMD fully off while charging.
All 12 threads available at full turbo. Zero performance penalty.

**How the thresholds work:** LPMD measures system-wide CPU utilization across
the cgroup. 4 E-cores at 100% = 100% util → exceeds exit threshold (40%) → P-cores
wake. 1-2 E-cores = ~25-50% → stays within hysteresis zone or below entry threshold.
This correctly distinguishes light work (browsing, terminal) from heavy workloads.

> **⚠️ System updates overwrite LPMD config.** `pacman -Syu` replaces this file
> with package defaults (e.g., `PowersaverDef=-1` = never enter LP mode on battery,
> `EntryHystMS=0` = no hysteresis → constant flapping). Fix:
> ```bash
> sudo chattr +i /etc/intel_lpmd/intel_lpmd_config.xml
> ```
> Or preserve on update:
> ```bash
> sudo pacman -Syu --overwrite /etc/intel_lpmd/intel_lpmd_config.xml
> ```

**Config:** `/etc/intel_lpmd/intel_lpmd_config.xml`
```xml
<Configuration>
  <lp_mode_cpus></lp_mode_cpus>
  <Mode>0</Mode>
  <PerformanceDef>-1</PerformanceDef>
  <BalancedDef>0</BalancedDef>
  <PowersaverDef>0</PowersaverDef>
  <HfiLpmEnable>0</HfiLpmEnable>
  <HfiSuvEnable>0</HfiSuvEnable>
  <util_entry_threshold>30</util_entry_threshold>
  <util_exit_threshold>40</util_exit_threshold>
  <EntryDelayMS>0</EntryDelayMS>
  <ExitDelayMS>0</ExitDelayMS>
  <EntryHystMS>5000</EntryHystMS>
  <ExitHystMS>1000</ExitHystMS>
  <IgnoreITMT>0</IgnoreITMT>
  <lp_mode_epp>150</lp_mode_epp>
</Configuration>
```

**Behavior:**
| State | LPMD profile | P-cores | E-cores |
|---|---|---|---|
| AC (charging) | Performance (`OFF`) | 8 threads @ full turbo | 4 cores @ full turbo |
| Battery idle (<30% util) | AUTO → LP mode | Parked via cgroup (C7, ~0W) | 4 cores active |
| Battery moderate (30-40%) | AUTO (hysteresis zone) | Stays in previous state | Stays in previous state |
| Battery load (>40% sustained) | AUTO → normal | 8 threads online | 4 cores online |
| Wake-up latency | ~1s (ExitHystMS) | P-cores re-added to cgroup | — |

**`nproc` shows 4 on battery:** When LPMD enters LP mode, it restricts
`user.slice` (your shell, apps) to CPUs 8-11 — the 4 E-cores. `nproc`
respects cgroup v2 CPU affinity, so it reports 4 instead of 12. This is
expected. Plug AC or load CPU >40% sustained to restore all 12.

### Idle power measurement

Script: `/home/ayu/.local/bin/idle-power`

Run after closing all apps to measure true idle power and find culprits:
```
idle-power
```

Does two 30s phases:
1. **turbostat** — CPU/package power breakdown (PkgWatt, CorWatt, GFXWatt, C-states)
2. **powertop** — device-level power usage + wakeup culprits

Output to `/tmp/idle-power-<timestamp>/` with summary showing:
- **Battery discharge vs PkgWatt gap** — unaccounted power (display, WiFi, NVMe, platform)
- **Device Power Usage** — which devices are active (Display backlight, NVMe, WiFi, Ethernet)
- **Untunable Issues** — devices missing runtime PM (e.g. I2C adapters)
- **Powertop Suggestions** — tunables to apply (auto-tune)

Target: <3W PkgWatt, <6W total discharge at true idle on battery.

Biggest idle culprits (typical):
  - Display backlight: ~1-3W
  - WiFi (iwlwifi): ~0.5W
  - NVMe: ~0.3W
  - Ethernet (r8169): ~0.5W (if link active)
  - I2C no-runtime-PM: ~0.1W (many devices, minor each)
- **Busy% / Bzy_MHz** — CPU utilization

Target: <3W PkgWatt at true idle (all apps closed, on battery).

**Why utilization-based over input-based:**

### Dirty writeback aggregation — reduce disk I/O

**Source:** [Arch Wiki — Power management / Writeback Time](https://wiki.archlinux.org/title/Power_management#Writeback_Time)

File: `/etc/sysctl.d/99-vm-dirty.conf`
```
vm.dirty_writeback_centisecs = 6000
vm.dirty_expire_centisecs = 12000
```
Increases writeback interval from 5s to 60s — aggregates disk writes into fewer, larger
I/O bursts, allowing the NVMe to stay in deeper power states longer.

### USB autosuspend + LPMD switching — udev rules (no scripts)

File: `/etc/udev/rules.d/99-usb-power.rules`
```
# AC: USB on, LPMD OFF (all cores, full perf)
ACTION=="add|change", SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="/bin/sh -c 'for f in /sys/bus/usb/devices/*/power/control; do echo on > $f 2>/dev/null; done'", RUN+="/usr/bin/intel_lpmd_control OFF"

# BAT: USB auto, LPMD AUTO (util-based, exits LP when >25% CPU)
ACTION=="add|change", SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="/bin/sh -c 'for f in /sys/bus/usb/devices/*/power/control; do echo auto > $f 2>/dev/null; done; for d in /sys/bus/usb/devices/*/; do case $(cat $d/idVendor 2>/dev/null):$(cat $d/idProduct 2>/dev/null) in 17ef:60a9) echo on > $d/power/control 2>/dev/null;; esac; done'", RUN+="/usr/bin/intel_lpmd_control AUTO"
```

**Supplementary systemd service** (fixes boot race — udev fires before LPMD is ready):
File: `/etc/systemd/system/lpmd-power-state.service`
```ini
[Unit]
Description=Set LPMD mode for current power source
After=intel_lpmd.service
Requires=intel_lpmd.service

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'grep -q 0 /sys/class/power_supply/ADP1/online && /usr/bin/intel_lpmd_control AUTO || /usr/bin/intel_lpmd_control OFF'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

**Effect:**
| State | USB autosuspend | Denylist (mouse) | LPMD |
|---|---|---|---|
| AC (charging) | Off (all `on`) | Off | OFF → all 12 cores |
| Battery idle | On (`auto`) | Stays `on` | AUTO → LP mode (E-cores 8-11 via cgroups) |
| Battery load (>40% sustained) | On (`auto`) | Stays `on` | AUTO → normal (all 12 cores, 1s hysteresis) |

**Adding to denylist:** run `usb-list` (in `~/.local/bin/`) to see vendor:product IDs,
then edit the `case` pattern: `sudoedit /etc/udev/rules.d/99-usb-power.rules`
and change `17ef:60a9|30c9:0069)` etc. Then `sudo udevadm control --reload-rules`.

TLP has `USB_AUTOSUSPEND=0` so it doesn't interfere.
LPMD config has `<Mode>0</Mode>` (OFF default), udev + systemd service override it.

### Bluetooth — `rfkill block` persists across reboots

`rfkill block bluetooth` disables the radio completely (~0W). State is saved by
`systemd-rfkill.service` and restored on next boot. No udev rules or scripts needed.

- Disable: `rfkill block bluetooth` (one time, persists)
- Enable: `rfkill unblock bluetooth` (until next reboot or manual block)
- Check: `rfkill list bluetooth`

No auto-management — never force-disconnects an active BT device.

### Kernel cmdline cleanup
Removed redundant `nmi_watchdog=0` (already covered by `nowatchdog`).

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

### i915 — PSR re-enabled with custom VBT

PSR was disabled (`i915.enable_psr=0`) due to AUX channel errors causing a 30s eDP link training loop on resume. A custom VBT (`/lib/firmware/i915/modified_vbt`) was created to fix the panel timing parameters (AUX timeouts, power sequencing, vswing levels).

**Fixed with custom VBT:** PSR re-enabled at `i915.enable_psr=2`, DC states stay disabled (`i915.enable_dc=0`).

| Metric | PSR off | PSR on + custom VBT |
|---|---|---|
| PSR AUX errors/boot | 0 | **0** |
| Suspend time | ~11s | **~13s** |
| Idle power | ~7.1W | **~4.4W** |

The custom VBT eliminated all PSR AUX errors. The 2s extra suspend time (vs PSR off) is the i915 driver waiting for the panel's PSR hardware to quiesce before shutting off the display pipeline — a panel-level limitation, not a driver bug.

**VBT details:**
- Platform: ALDERLAKE-P
- BDB version: 251
- Panel: LFP1 (internal BOE display) via eDP
- Key PSR timings: TP1 wakeup 200µs, TP2/TP3 200µs, PSR2 2500µs
- Panel power sequence: T1-T3=2000ms, T8=10ms, T9=2000ms, T10=500ms, T11-T12=5000ms

Decode:
```bash
intel_vbt_decode /lib/firmware/i915/modified_vbt
```

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
KERNEL_CMDLINE[default]+="nvidia-drm.modeset=1 quiet nowatchdog i915.enable_psr=2 i915.enable_fbc=1 i915.enable_dc=0 iwlwifi.power_save=1 rw rootflags=subvol=/@ root=UUID=f7d828f3-6031-4f9b-a164-fed7f21a082b tpm_tis.interrupts=0 resume=UUID=89bc64d4-f652-4586-bb5a-35b6ffa13719 i915.vbt_firmware=i915/modified_vbt nvme_core.default_ps_max_latency_us=0"
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
| Masked `systemd-userdbd` + socket | None | Service removal — no runtime impact |
| Masked `lvm2-monitor` | None | Service removal — no runtime impact |
| `DefaultDependencies=no` nvidia-persistenced | None | Service still starts, just not on critical chain |
| `i915.enable_psr=2` with custom VBT | Positive | iGPU enters RC6 idle, saves ~2.7W at idle |
| `intel_lpmd` BalancedDef=0 | Positive | Utilization-based P-core parking on battery, E-cores only below 30% util (~1-2W saving) |
| `vm.dirty_writeback_centisecs=6000` | Slightly positive | Aggregates disk I/O, NVMe stays in deep power states longer |
| USB + LPMD udev switching | Positive | USB autosuspends on battery (~0.1-0.3W). LPMD parks P-cores under 30% util (~1-2W), wakes them above 40% sustained. |
| Bluetooth `rfkill block` | Positive (when off) | Radio fully disabled (~0W). Persists across reboots. Manual toggle — never force-disconnects. |
