# Intel i915 eDP link training failure after suspend (Alder Lake-P + NVIDIA Hybrid)

**Arch Wiki reference:** [Intel graphics — Freeze after wake from sleep (Raptor Lake / Alder Lake-P)](https://wiki.archlinux.org/title/Intel_graphics#Freeze_after_wake_from_sleep/suspend_with_Raptor_Lake_and_Alder_Lake-P)

---

## The problem

On HP Victus (and similar) laptops with Intel Alder Lake-P + NVIDIA dGPU, the BIOS VBT contains **duplicate eDP child device entries** (LFP1 + LFP2). After s2idle suspend/resume, the i915 driver tries to train the eDP link on both ports. The second port (DP-B) has no physical panel, causing:

```
i915 0000:00:02.0: [drm] *ERROR* [CONNECTOR:eDP-1][ENCODER:DDI A/PHY A][DPRX] Failed to enable link training
```

This repeats every ~24s and blocks modeset operations (refresh rate changes, compositor output reconfiguration), with Waybar typically crashing in `handleOutputDone`.

## The fix

Disable the duplicate LFP2 entry in the VBT by changing its device type from `0x1806` (eDP) to `0x0000` (disabled), then load the patched VBT via `i915.vbt_firmware`.

### Step-by-step

**1. Extract the original VBT**

```bash
cat /sys/kernel/debug/dri/0000:00:02.0/i915_vbt > /tmp/vbt.bin
cp /tmp/vbt.bin /tmp/vbt_original.bin
```

**2. Find the duplicate LFP2 entry**

The two eDP child devices appear at these offsets (verify with `xxd`):

| Entry | Offset | Handle | Device type |
|-------|--------|--------|-------------|
| LFP1 (real panel) | `0x18d` | `0x0008` | `0x1806` |
| LFP2 (duplicate) | `0x1b4` | `0x0080` | `0x1806` |

Check your offsets:
```bash
python3 -c "
with open('/tmp/vbt.bin', 'rb') as f:
    data = f.read()
for i in range(len(data)-4):
    if data[i:i+2] == b'\x08\x00' and data[i+2:i+4] == b'\x06\x18':
        print(f'LFP1 at 0x{i:x}')
    if data[i:i+2] == b'\x80\x00' and data[i+2:i+4] == b'\x06\x18':
        print(f'LFP2 at 0x{i:x} (DUPLICATE)')
"
```

**3. Patch the duplicate**

```bash
# Change device type 0x1806 -> 0x0000 at offset 0x1b6
printf '\x00\x00' | dd of=/tmp/vbt.bin bs=1 seek=$((0x1b6)) conv=notrunc
```

**4. Verify the patch**

```bash
# Check LFP2 device type is now 0x0000
python3 -c "
with open('/tmp/vbt.bin', 'rb') as f:
    data = f.read()
h2 = int.from_bytes(data[0x1b4:0x1b6], 'little')
t2 = int.from_bytes(data[0x1b6:0x1b8], 'little')
print(f'LFP2: handle=0x{h2:04x}, type=0x{t2:04x}')
assert h2 == 0x0080
assert t2 == 0x0000
print('OK - duplicate disabled')
"
```

```bash
# Verify the VBT still decodes correctly
intel_vbt_decode /tmp/vbt.bin | grep -A2 'Child device info:'
# LFP2 should no longer appear
```

**5. Install the patched VBT**

```bash
sudo mkdir -p /lib/firmware/i915
sudo cp /tmp/vbt.bin /lib/firmware/i915/modified_vbt
```

**6. Add to initramfs**

Add to `/etc/mkinitcpio.conf`:
```ini
FILES=(/lib/firmware/i915/modified_vbt)
```

**7. Add kernel parameter**

Add `i915.vbt_firmware=i915/modified_vbt` to your bootloader kernel cmdline.

For **Limine** (`/boot/limine.conf`):
```
cmdline: ... i915.vbt_firmware=i915/modified_vbt
```

For **systemd-boot** (`/boot/loader/entries/*.conf`):
```
options ... i915.vbt_firmware=i915/modified_vbt
```

**8. Regenerate initramfs**

```bash
sudo mkinitcpio -P
```

**9. Reboot**

---

## Additional notes

- `mem_sleep_default=deep` would force S3 sleep but most modern laptops (including HP Victus) only support **s2idle** — check with `cat /sys/power/mem_sleep`
- The duplicate VBT is a **BIOS bug** from HP — it won't be fixed by kernel updates
- If the VBT fix alone isn't enough, switching to **Integrated GPU only** in BIOS also works (confirmed in [Pop!_OS issue #3874](https://github.com/pop-os/pop/issues/3874))

---

## AI prompt to recreate this fix

```
I have an HP Victus laptop with Intel Alder Lake-P + NVIDIA hybrid graphics.
After suspend/resume, the internal display shows this kernel error repeatedly:

  i915 0000:00:02.0: [drm] *ERROR* [CONNECTOR:eDP-1][ENCODER:DDI A/PHY A][DPRX] Failed to enable link training

The Arch Wiki says this is caused by duplicate eDP entries in the BIOS VBT.

Please help me:
1. Extract the VBT from /sys/kernel/debug/dri/0000:00:02.0/i915_vbt
2. Find the duplicate LFP2 child device entry (handle 0x0080, type 0x1806)
3. Patch its device type from 0x1806 to 0x0000 to disable it
4. Install the patched VBT to /lib/firmware/i915/modified_vbt
5. Add it to initramfs via mkinitcpio.conf FILES
6. Add kernel parameter i915.vbt_firmware=i915/modified_vbt
7. Rebuild initramfs

My bootloader is [limine/systemd-boot/grub]. Check /sys/power/mem_sleep first
to see if deep sleep is supported.
```

---

## Hibernation setup

### Overview

System only supports **s2idle** (no S3/deep sleep). Hibernation (suspend-to-disk) provides true power-off and is configured via a dedicated swap partition.

| Component | Value |
|-----------|-------|
| Swap device | `/dev/nvme0n1p8` (9.8 GiB) |
| Swap UUID | `89bc64d4-f652-4586-bb5a-35b6ffa13719` |
| Resume kernel param | `resume=UUID=89bc64d4-f652-4586-bb5a-35b6ffa13719` |
| Initramfs | systemd-based (`systemd` hook) — no `resume` hook needed |
| Bootloader | Limine — cmdline sourced from `/etc/default/limine` |

### Swap partition

The unused `nvme0n1p8` (formerly ext4) was converted to swap:

```bash
swapoff /dev/zram0
mkswap /dev/nvme0n1p8
swapon /dev/nvme0n1p8
```

Added to `/etc/fstab`:
```ini
UUID=89bc64d4-f652-4586-bb5a-35b6ffa13719 none swap defaults 0 0
```

`zram0` is kept with higher priority (`pri=100`) for regular swapping; systemd ignores zram for hibernation.

### Kernel parameter

Added to `/etc/default/limine` (source of truth for Limine cmdline):

```
KERNEL_CMDLINE[default]+="... resume=UUID=89bc64d4-f652-4586-bb5a-35b6ffa13719 i915.vbt_firmware=i915/modified_vbt"
```

Regenerated with `limine-update` (which also runs `mkinitcpio -P`).

### suspend-then-hibernate (optional)

Configured in `/etc/systemd/sleep.conf.d/hibernate.conf`:

```ini
[Sleep]
HibernateDelaySec=30min
```

Use `systemctl suspend-then-hibernate` to suspend first, then auto-hibernate after 30 min. Or use `systemctl hibernate` to hibernate immediately.

### Test

```bash
sudo systemctl hibernate
# System powers off. Power on to resume.
```

---

## AI prompt to recreate hibernation setup

```
I have an HP Victus (or similar) laptop with Intel Alder Lake-P + NVIDIA hybrid
graphics. I already fixed the i915 eDP link training failure by patching the VBT
and loading it via i915.vbt_firmware.

Now I need to add hibernation support. The system only supports s2idle (no S3).

- RAM size: 7.4 GiB
- Current swap: zram only (not usable for hibernation)
- There is an unused 9.8 GiB partition (/dev/nvme0n1p8) available
- Initramfs: mkinitcpio with the `systemd` hook (not busybox)
- Bootloader: Limine (cmdline configured via /etc/default/limine)
- UEFI system

Please set up hibernation by:
1. Converting the unused partition to swap
2. Adding it to /etc/fstab by UUID
3. Adding resume=UUID=... to the kernel cmdline in /etc/default/limine
4. Updating initramfs and bootloader config
5. Optionally configuring suspend-then-hibernate with a delay
```
