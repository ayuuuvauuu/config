#!/bin/bash
# Fix audio powersave race + dual output (Auto-Mute)
set -e
# Fix dual output
amixer -c1 sset 'Auto-Mute Mode' Enabled >/dev/null 2>&1 || true
if amixer -c1 cget numid=12 2>/dev/null | grep -q "values=on"; then
  amixer -c1 sset Speaker mute >/dev/null 2>&1 || true
fi
amixer -c1 sset Headphone unmute >/dev/null 2>&1 || true
amixer -c1 sset Master unmute >/dev/null 2>&1 || true
# powersave
if [ -w /sys/module/snd_hda_intel/parameters/power_save ]; then
  echo 0 > /sys/module/snd_hda_intel/parameters/power_save || true
  echo "[fix-audio] set power_save=0"
else
  if sudo -n true 2>/dev/null; then echo 0 | sudo tee /sys/module/snd_hda_intel/parameters/power_save >/dev/null && echo "[fix-audio] via sudo"; else echo "[fix-audio] cannot write power_save need sudo current: $(cat /sys/module/snd_hda_intel/parameters/power_save)"; fi
fi
for f in /sys/bus/hdaudio/devices/*/power/control; do [ -f "$f" ] && echo on > "$f" 2>/dev/null || sudo sh -c "echo on > $f" 2>/dev/null || true; done
