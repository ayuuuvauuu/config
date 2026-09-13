#!/bin/bash
# fix-firefox-audio.sh - Permanent fix for Firefox + dual-output
# Victus ALC245 sof-hda-dsp PipeWire 1.6.8 Firefox
set -eu
SINK="alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Headphones__sink"
LOG() { echo "[fix-firefox] $*"; }

# 0. Fix dual output: Auto-Mute must be Enabled, Speaker muted when HP jack on
if amixer -c1 contents 2>/dev/null | grep -q "Auto-Mute Mode"; then
  amixer -c1 sset 'Auto-Mute Mode' Enabled >/dev/null 2>&1 || true
  # if Headphone jack is on (plugged), keep Speaker muted
  if amixer -c1 cget numid=12 2>/dev/null | grep -q "values=on"; then
    amixer -c1 sset Speaker mute >/dev/null 2>&1 || true
  fi
  amixer -c1 sset Headphone unmute >/dev/null 2>&1 || true
  amixer -c1 sset Master unmute >/dev/null 2>&1 || true
fi

# 1. default sink -> Headphones
CURRENT=$(pactl get-default-sink 2>/dev/null || echo "")
if [ "$CURRENT" != "$SINK" ]; then
  LOG "default sink $CURRENT -> $SINK"
  pactl set-default-sink "$SINK" 2>/dev/null || true
fi
pactl set-sink-mute "$SINK" 0 2>/dev/null || true
wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 2>/dev/null || true
if [ -w /sys/module/snd_hda_intel/parameters/power_save ]; then echo 0 > /sys/module/snd_hda_intel/parameters/power_save 2>/dev/null || true; fi

# 2. move all Firefox streams to Headphones + unmute (fixes HDMI wrong sink after restart)
for id in $(pactl list sink-inputs short 2>/dev/null | awk '{print $1}'); do
  if pactl list sink-inputs 2>/dev/null | grep -A15 "Sink Input #$id" | grep -q "Firefox"; then
    LOG "fix firefox $id -> $SINK"
    pactl move-sink-input "$id" "$SINK" 2>/dev/null || true
    pactl set-sink-input-mute "$id" 0 2>/dev/null || true
    pactl set-sink-input-volume "$id" 65536 2>/dev/null || true
  fi
done

LOG "sinks:"; pactl list sinks short 2>/dev/null | grep -E "Headphones|HDMI" | head -n 5
LOG "sink-inputs:"; pactl list sink-inputs short 2>/dev/null | head -n 5
CORKED=$(pactl list sink-inputs 2>/dev/null | grep -c "Corked: yes" || true)
RUNNING=$(pactl list sink-inputs 2>/dev/null | grep -c "Corked: no" || true)
[ "$CORKED" -gt 0 ] && [ "$RUNNING" -eq 0 ] && LOG "All Firefox corked (paused tabs) -> press Play" || true
LOG "Headphones state: $(pactl list sinks short 2>/dev/null | grep Headphones || echo missing)"
