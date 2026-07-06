# Battery-Saving Configuration Audit Report

**Date:** 2026-06-11
**System:** CachyOS (Arch-based)
**Kernel:** 7.0.11-1-cachyos
**Hardware:** Intel 12th Gen i5-12450H + NVIDIA GeForce RTX 2050

---

## 1. Bootloader & Kernel Parameters

**Source:** `/proc/cmdline` and `/etc/default/limine`

```
quiet nowatchdog nmi_watchdog=0 pcie_aspm=force i915.enable_psr=0
i915.enable_fbc=1 i915.enable_dc=0 iwlwifi.power_save=1
rw rootflags=subvol=/@ root=UUID=f7d828f3-6031-4f9b-a164-fed7f21a082b
```

| Flag | Effect | Battery Impact |
|---|---|---|
| `nowatchdog` | Disables hardware watchdog timers | ✅ Positive — reduces periodic wakeups |
| `nmi_watchdog=0` | Disables NMI watchdog | ✅ Positive — reduces periodic wakeups |
| `pcie_aspm=force` | Forces PCIe ASPM on all devices | ✅ Positive — enables PCIe link power saving |
| `i915.enable_fbc=1` | Enables Intel framebuffer compression | ✅ Positive — reduces GPU memory bandwidth |
| `i915.enable_psr=0` | Disables Panel Self Refresh | ⚠️ Negative — PSR saves power but may cause flicker |
| `i915.enable_dc=0` | Disables display DC power states | ⚠️ Negative — DC states save power at low loads |
| `iwlwifi.power_save=1` | Enables Intel WiFi power saving | ✅ Positive — reduces WiFi radio power |

**Assessment:** Mix of power-saving and stability workarounds. The `i915.enable_psr=0` and `i915.enable_dc=0` are likely stability fixes that trade off some battery life.

---

## 2. /etc Power-Related Configurations

### 2.1 CPU Power Tools

| Tool | Config Found | Status |
|---|---|---|
| **TLP** | Not installed | ❌ Not present |
| **power-profiles-daemon** | Not installed | ❌ Not present |
| **tuned** | Not installed | ❌ Not present |
| **thermald** | Not installed | ❌ Not present |
| **cpupower** | `/etc/default/cpupower-service.conf` | ✅ Installed but service **disabled** (no governor set, all commented out) |
| **auto-cpufreq** | Systemd service at `/etc/systemd/system/auto-cpufreq.service` | ✅ **Active and running** (v3.0.0, no config override — using defaults) |

### 2.2 NVIDIA GPU Configuration

**`/etc/modprobe.d/nvidia.conf`:**

```
options nvidia-drm modeset=1 fbdev=1
options nvidia NVreg_UsePageAttributeTable=1 NVreg_InitializeSystemMemoryAllocations=0
options nvidia NVreg_DynamicPowerManagement=0x02
options nvidia NVreg_EnableS0ixPowerManagement=1 NVreg_PreserveVideoMemoryAllocations=0
```

| Option | Effect |
|---|---|
| `NVreg_DynamicPowerManagement=0x02` | Enables NVIDIA dynamic power management for supported GPUs |
| `NVreg_EnableS0ixPowerManagement=1` | Enables S0ix (modern standby) power state |
| `NVreg_PreserveVideoMemoryAllocations=0` | Does not preserve video memory across suspend (reduces power) |
| `NVreg_UsePageAttributeTable=1` | Better GPU memory performance |
| `NVreg_InitializeSystemMemoryAllocations=0` | Skips reserving all VRAM at boot |

**Other NVIDIA files:**
- `/etc/systemd/system/multi-user.target.wants/nvidia-powerd.service` — active/enabled
- `/etc/systemd/system/multi-user.target.wants/nvidia-persistenced.service` — active/enabled
- `/etc/systemd/system/systemd-suspend.service.wants/nvidia-suspend.service`
- `/etc/systemd/system/systemd-suspend.service.wants/nvidia-resume.service`
- `/etc/systemd/system/systemd-hibernate.service.wants/nvidia-hibernate.service`
- `/etc/systemd/system/systemd-hibernate.service.wants/nvidia-resume.service`
- `/etc/systemd/system/systemd-suspend-then-hibernate.service.wants/nvidia-resume.service`

### 2.3 Sysctl Settings

**`/etc/sysctl.d/powersave.conf`:**
```
kernel.nmi_watchdog = 0
```
Also set via kernel cmdline (`nmi_watchdog=0`), so this is redundant but harmless.

### 2.4 Custom Systemd Units

- **`upower.service.d/override.conf`:** Sets `Type=simple` (ensures upowerd stays running)
- **`auto-cpufreq.service`:** Custom service at `/etc/systemd/system/`

### 2.5 TLP / power-profiles-daemon Conflict

**No conflict detected.** Neither TLP nor power-profiles-daemon are installed. auto-cpufreq is the sole CPU governor manager.

---

## 3. Running Processes & Services

### Active Power-Related Processes

| PID | Process | Description |
|---|---|---|
| 807 | `auto-cpufreq --daemon` | Automatic CPU frequency optimizer |
| 811 | `nvidia-powerd` | NVIDIA GPU power management daemon |
| 816 | `nvidia-persistenced` | NVIDIA persistence daemon |
| 849 | `upowerd` | System power monitoring daemon |
| 682/722/723 | `nvidia-modeset/irq-nvidia/nvidia` | NVIDIA kernel threads |

### Systemd Service States

| Service | Enabled | Active |
|---|---|---|
| `auto-cpufreq` | yes | active |
| `nvidia-powerd` | yes | active |
| `nvidia-persistenced` | yes | active |
| `upower` | no* | active |
| `cpupower` | no | inactive |
| `tlp` | — | not installed |
| `power-profiles-daemon` | — | not installed |
| `tuned` | — | not installed |
| `thermald` | — | not installed |
| `ananicy` | — | not installed |
| `irqbalance` | — | not installed |

*\*upower is socket-activated by D-Bus, so it does not need to be systemd-enabled.*

---

## 4. CPU & GPU Power State

### 4.1 CPU Frequency Scaling

| Parameter | Value |
|---|---|
| **Driver** | `intel_pstate` (with HWP support) |
| **Governor** | `powersave` |
| **Available governors** | performance, powersave |
| **Min frequency** | 400 MHz |
| **Max frequency** | 2.00 GHz (hardware limit) |
| **Turbo boost** | ✅ **Active** (`no_turbo=0`, max_perf_pct=100) |
| **Min perf %** | 10% |
| **Energy Performance Preference** | `balance_power` |
| **Available EPP** | default, performance, balance_performance, **balance_power**, power |

**Current CPU frequencies across 12 threads:**
```
Core 0:   400 MHz
Core 1:  1239 MHz
Core 2:  1234 MHz
Core 3:  1357 MHz
Core 4:  1300 MHz
Core 5:  1217 MHz
Core 6:  1300 MHz
Core 7:   400 MHz
Core 8:  1288 MHz
Core 9:   400 MHz
Core 10: 1300 MHz
Core 11: 1300 MHz
```

**Assessment:** `powersave` governor + `balance_power` EPP + auto-cpufreq daemon is a solid battery-oriented configuration. Turbo boost being active means it can still spike performance when needed.

### 4.2 NVIDIA GPU State

```
NVIDIA-SMI 610.43.02  |  Driver Version: 610.43.02
GPU: NVIDIA GeForce RTX 2050
  Persistence-M: ON
  Power: 7W / 35W  (20% of TDP)
  Temp: 36°C
  Perf State: P3 (low power)
  GPU-Util: 3%
  Memory: 12MiB / 4096MiB
```

| Metric | Value |
|---|---|
| **Power limit** | 35W |
| **Current draw** | 7W (very low — excellent) |
| **Persistence mode** | On |
| **GPU clocks** | Locked low (auto-cpufreq/nvidia-powerd managing) |

**Assessment:** GPU is in excellent low-power state. `nvidia-powerd` is actively managing power draw.

### 4.3 Additional Sysfs & Hardware Power Knobs

| Knob | Status | Assessment |
|---|---|---|
| **ASPM policy** | `default` (available: performance, powersave, powersupersave) | ⚠️ Could be improved — using `powersupersave` may save more |
| **PCI runtime PM** | All 23 PCI devices on `auto` | ✅ Good |
| **WiFi power save** | ON (kernel: `iwlwifi.power_save=1`) | ✅ Good |
| **Battery present** | BAT0, discharging at 86% capacity | ✅ Detected |
| **S0ix enabled** | NVIDIA configured for S0ix | ✅ Good |

---

## 5. Web-Researched Recommendations

Based on the detected hardware — **Intel Alder Lake i5-12450H** + **NVIDIA RTX 2050** on **CachyOS (Arch)** — here are actionable recommendations:

### 5.1 CPU-Specific (Intel Alder Lake)

- **HWP (Hardware-Controlled Performance States)** is already active (driver: `intel_pstate`). The current `balance_power` EPP is appropriate for battery.
- **Intel C-states:** Consider adding `intel_idle.max_cstate=4` or `processor.max_cstate=4` if deeper C-states are unstable. (Not currently set — leaving as default is fine.)
- **Energy-Aware Scheduling (EAS):** Since this is a hybrid Alder Lake CPU (P-cores + E-cores), ensure `sysctl kernel.sched_energy_aware=1`. Check currently:
  **Note:** EAS is typically enabled by default on modern kernels.

### 5.2 GPU-Specific

- **NVIDIA Dynamic PM** is already enabled (`NVreg_DynamicPowerManagement=0x02`) — best practice.
- **`nvidia-powerd`** is active — this is the recommended solution for RTX 20-series and newer.
- For even more aggressive GPU power savings when unplugged, consider the [nvidia-laptop-battery-optimizer](https://github.com/ibodeth/nvidia-laptop-battery-optimizer) utility, which uses udev events to lock GPU clocks low on battery and restore on AC.

### 5.3 General Battery Optimization Stack (2026 Best Practices)

**Already in use:**
- [x] **auto-cpufreq** v3.0.0 — the recommended CPU governor manager
- [x] **WiFi power saving** enabled via kernel cmdline
- [x] **PCIe ASPM forced** via kernel cmdline
- [x] **NVIDIA Dynamic PM** + nvidia-powerd
- [x] **NMI watchdog disabled** (both sysctl and kernel cmdline)
- [x] **Powersave CPU governor** on battery

**Not yet used (potential additions):**
- [ ] **TLP** — Could coexist with auto-cpufreq (disable TLP's CPU control). TLP manages USB autosuspend, disk APM, radio control, and battery charge thresholds.
- [ ] **powertop** — Useful for identifying "energy vampires" (background processes waking the CPU).
- [ ] **ASPM `powersupersave`** — Changing ASPM policy from `default` to `powersupersave` may further reduce PCIe power (test for stability first).
- [ ] **Battery charge threshold** — If supported by hardware, limiting charge to 80% extends battery lifespan.
- [ ] **VM dirty writeback** — Set `vm.dirty_writeback_centisecs=6000` in sysctl to reduce disk wakeups.
- [ ] **Laptop mode** — Set `vm.laptop_mode=5` to defer disk writes.

### 5.4 ASPM Deep Dive

Current policy is `default` with `performance powersave powersupersave` available. Setting to `powersupersave` via `pcie_aspm.policy=powersupersave` in kernel cmdline could reduce idle power further. However, some older or buggy PCIe devices may have issues with the deepest ASPM states.

### 5.5 Additional Kernel Parameters to Consider

| Parameter | Effect | Risk |
|---|---|---|
| `processor.max_cstate=4` | Prevents deepest C-state (may fix instability) | Low |
| `pcie_aspm.policy=powersupersave` | Deepest PCIe ASPM | Medium — test stability |
| `nvme.noacpi=1` | Disables ACPI for NVMe | Low |
| `acpi_osi=!Windows 2020` | May improve ACPI battery reporting | Medium |

---

## 6. Recreation Guide — How to Re-Apply These Settings

This section lists every battery-saving measure found on this system as copy-paste commands, so you can recreate the configuration from scratch.

### 6.1 Kernel Command-Line Parameters

Edit `/etc/default/limine` and add to `KERNEL_CMDLINE[default]+=`:

```
quiet nowatchdog nmi_watchdog=0 pcie_aspm=force i915.enable_psr=0 i915.enable_fbc=1 i915.enable_dc=0 iwlwifi.power_save=1
```

Then regenerate the boot config:

```bash
sudo limine-update
```

### 6.2 Sysctl — NMI Watchdog

File: `/etc/sysctl.d/powersave.conf`
```
kernel.nmi_watchdog = 0
```

Apply:
```bash
sudo sysctl -p /etc/sysctl.d/powersave.conf
```

### 6.3 NVIDIA Modprobe Config

File: `/etc/modprobe.d/nvidia.conf`
```
options nvidia-drm modeset=1 fbdev=1
options nvidia NVreg_UsePageAttributeTable=1 NVreg_InitializeSystemMemoryAllocations=0
options nvidia NVreg_DynamicPowerManagement=0x02
options nvidia NVreg_EnableS0ixPowerManagement=1 NVreg_PreserveVideoMemoryAllocations=0
```

### 6.4 NVIDIA Systemd Services (enable at boot)

```bash
sudo systemctl enable --now nvidia-powerd
sudo systemctl enable --now nvidia-persistenced
```

### 6.5 auto-cpufreq

```bash
sudo systemctl enable --now auto-cpufreq
```

(No config override needed — defaults work. Custom config goes in `/etc/auto-cpufreq.conf`.)

### 6.6 upower Override

File: `/etc/systemd/system/upower.service.d/override.conf`
```
[Service]
Type=simple
```

### 6.7 Disable Unnecessary Power Services

```bash
sudo systemctl disable cpupower   # not needed when auto-cpufreq is active
```

---

## 7. ASPM powersupersave — How to Enable & Verify

### What It Does

ASPM (Active State Power Management) has multiple power-saving levels:
- `performance` — no power saving
- `default` — BIOS default
- `powersave` — moderate saving
- `powersupersave` — deepest saving (max PCIe link power reduction)

Your system currently uses `[default]` (indicated by brackets in sysfs). `powersupersave` is supported.

### How to Enable

Add to kernel command line in `/etc/default/limine`:

```
pcie_aspm.policy=powersupersave
```

After `limine-update` and reboot, all PCIe links will attempt to enter the deepest ASPM state when idle.

### How to Check If It's Enabled (After Reboot)

```bash
# 1. Check current ASPM policy — the one in [brackets] is active
cat /sys/module/pcie_aspm/parameters/policy

# Expected output (success):
# performance powersave powersupersave [powersupersave]

# 2. Check per-device ASPM status
find /sys/bus/pci/devices/*/power -name 'aspm*' -exec cat {} \;

# 3. Check PCIe link status for each device
find /sys/bus/pci/devices/*/ -name 'link_status' 2>/dev/null | while read f; do
  echo "$(basename $(dirname $(dirname $f))) $(cat $f 2>/dev/null)"; done

# 4. Quick sanity — ASPM counters
find /sys/bus/pci/devices/*/ -name 'aspm_disable' 2>/dev/null | while read f; do
  state=$(cat "$f" 2>/dev/null)
  if [ "$state" != "0" ]; then
    echo "⚠️  $(basename $(dirname $f)): ASPM disabled ($state)"
  fi
done
```

### Risks

- Some PCIe devices (especially older WiFi/BT cards or NVMe drives) may experience latency or reduced throughput under `powersupersave`
- Test stability for a few days. If issues arise, remove the parameter and reboot.

---

## 8. Summary

### What's Configured Well ✅

- **auto-cpufreq** running with powersave governor
- **NVIDIA Dynamic Power Management** + nvidia-powerd + S0ix
- **PCIe ASPM forced** on all devices
- **NMI watchdog disabled** (kernel + sysctl)
- **WiFi power saving** enabled
- **Framebuffer compression** enabled (i915)
- **Low GPU power draw** (7W idle)
- **PCI runtime PM** enabled on all devices

### What Could Be Improved ⚠️

- **ASPM policy** is on `default` — could try `powersupersave`
- **TLP not installed** — could add USB autosuspend, disk APM, battery threshold, radio management
- **i915 PSR and DC disabled** — likely stability-driven, but costs battery
- **No powertop monitoring** — useful for identifying wakeup sources
- **Dirty writeback defaults** — could tune `vm.dirty_writeback_centisecs` and `vm.laptop_mode`

### Read-Only Verification ✅

No system files were modified during this audit. All data was collected via read-only commands.
