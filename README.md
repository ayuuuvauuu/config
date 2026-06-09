# Config & Notes

## Clean Install
- read full https://github.com/swaywm/sway/wiki
- install `gammastep`
- install waybar from my github
- set fish default term
- install battery saver tools
- fix screen sharing: https://bbs.archlinux.org/viewtopic.php?id=291201
- install apps from apps/ and programming/opt/
- gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'

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


## Hibernate Fix
```bash
sudo systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service
```
Add `nvidia.NVreg_PreserveVideoMemoryAllocations=1` to kernel params.

## Power Tools
```bash
powertop --calibrate && powertop --auto-tune
```

- auto-cpufreq
- ananicy-cpp

## Misc
- install `bleachbit` to clean old files
- `pip install i3ipc`
- `astrortm`, `delta` (git pager), `so` (tui for stackoverflow)
- remove all `fish.tmp.*` from fish dir to clear temp env vars
- install `unp`
- screenshot: `screensy` https://screensy.marijn.it
- font check: `fc-list`
- switch to g++ 12 if nvim errors


## Gaming
```bash
PROTON_USE_NTSYNC=1 PROTON_ENABLE_WAYLAND=1 -noeac -setfps 140 -triplebuffer -nonetworknext -high
```

Change TTL to 65 to trick ISP (not a hotspot):
```bash
# TODO: add command
```

## Sway Screen Sharing
put in `/etc/sway/config.d/`:
```
exec --no-startup-id dbus-update-activation-environment --systemd \
   WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway XDG_SESSION_DESKTOP=sway XDG_SESSION_TYPE=wayland
exec --no-startup-id systemctl --user start pipewire wireplumber xdg-desktop-portal xdg-desktop-portal-wlr
```

## Wayland Recording
use `gpu-screen-recorder-gtk`  
use `h264ify` for youtube hardware accel & less battery

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

## Neovim Config
https://github.com/ayuuuvauuu/nvchad

## Fish Key Bindings
```bash
fzf_configure_bindings --help
```

---

# Power Saving (applied 2026-06-07)

## Kernel Params (in `/etc/default/limine`)
need restart for effect.

| Param | What | Save |
|---|---|---|
| `nmi_watchdog=0` | stop watchdog that bites CPU every sec | ~0.5W |
| `pcie_aspm=force` | PCI slots go sleep when idle | ~0.5W |
| `i915.enable_psr=2` | panel self-refresh, redraw only changes | ~0.3W |
| `i915.enable_fbc=1` | compress framebuffer data | ~0.1W |
| `i915.enable_dc=4` | deep display C-states | ~0.1W |
| `iwlwifi.power_save=1` | wifi naps when idle | ~0.2W |

## Intel LPMD (fixed)
`/etc/intel_lpmd/intel_lpmd_config.xml`
- `PowersaverDef`: `-1` (never) → `1` (always on battery)

## Sysctl
`/etc/sysctl.d/powersave.conf`
- `kernel.nmi_watchdog = 0`

## Avahi (killed)
restart: `sudo systemctl enable --now avahi-daemon`

## Bluetooth (locked)
```bash
sudo rfkill unblock bluetooth && sudo systemctl start bluetooth
```

## NVIDIA D3Cold Check
```bash
cat /sys/bus/pci/devices/0000:01:00.0/power_state
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status
```

## Suspend Fix (Lid Close & Fast Suspend)

### Problem
- Lid close was suspending the system (systemd-logind default)
- Suspend was slow (~30s) due to i915 PSR link training loop + NVIDIA VRAM dump

### Changes

**1. systemd-logind — lid close = screen off only**
File: `/etc/systemd/logind.conf`
```
HandleLidSwitch=ignore          # was: #HandleLidSwitch=suspend
```
Then: `sudo systemctl restart systemd-logind`

**2. NVIDIA — skip VRAM dump for fast suspend**
File: `/etc/modprobe.d/nvidia.conf`
```
options nvidia NVreg_EnableS0ixPowerManagement=1 NVreg_PreserveVideoMemoryAllocations=0
```
Reboot required.

**3. i915 — disable PSR & DC states (was causing 20s eDP link training loop on resume)**
Files:
- `/boot/loader/entries/linux-cachyos1.conf`
- `/boot/loader/entries/linux-cachyos2.conf`
- `/etc/default/limine` (template)
- `/boot/limine.conf` (live config)

Changed kernel cmdline:
```
i915.enable_psr=0 i915.enable_dc=0    # was: i915.enable_psr=2 i915.enable_dc=4
```
Also removed `nvidia.NVreg_PreserveVideoMemoryAllocations=1` from systemd-boot entries (set in modprobe.d instead).

### Result (PSR off vs on)
| Metric | Before (PSR on) | After (PSR off) |
|--------|----------------|-----------------|
| `enable_psr` | 2 | 0 |
| `enable_dc` | 4 | 0 |
| PSR aux errors/boot | 2 | 0 |
| Suspend time | ~30s | ~14s |
| Idle power | ~11W | ~13W (fluctuates) |

PSR aux errors gone. Suspend ~2x faster. Link training still fails once on resume (known i915 runtime PM bug on HP Victus dual-GPU — kernel issue, no userspace fix).

### NVIDIA RTD3 — dGPU power management
**Problem**: dGPU idles at 5-7W, power fluctuates, never enters D3cold.
**Files**:
- `/etc/udev/rules.d/80-nvidia-pm.rules` — PCI runtime PM rules
- `nvidia-persistenced.service` — enabled (systemctl)

Allows GPU to enter D3cold (~0W) when idle. Reboot required for full effect.

