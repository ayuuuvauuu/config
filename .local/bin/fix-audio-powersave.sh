#!/bin/bash
# Fix audio powersave race at runtime (no sudo for /sys, but we can try if sudo available)
# This script mirrors what 20-audio-pm.rules + TLP do, but forces stable 0
set -e
if [ -w /sys/module/snd_hda_intel/parameters/power_save ]; then
  echo 0 > /sys/module/snd_hda_intel/parameters/power_save || true
  echo "[fix-audio] set power_save=0 via direct write"
else
  # try with sudo if password available
  if sudo -n true 2>/dev/null; then
    echo 0 | sudo tee /sys/module/snd_hda_intel/parameters/power_save >/dev/null && echo "[fix-audio] set power_save=0 via sudo"
  else
    echo "[fix-audio] cannot write power_save (need sudo), current: $(cat /sys/module/snd_hda_intel/parameters/power_save)"
  fi
fi
# Also set codec power control to on (prevent D3)
for f in /sys/bus/hdaudio/devices/*/power/control; do
  [ -f "$f" ] && echo on > "$f" 2>/dev/null || sudo sh -c "echo on > $f" 2>/dev/null || true
done
cat /sys/module/snd_hda_intel/parameters/power_save 2>/dev/null || true
