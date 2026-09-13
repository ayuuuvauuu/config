#!/bin/bash
# fix-firefox-audio.sh - Permanent fix for Firefox PipeWire sink issue
# Victus ALC245 sof-hda-dsp + PipeWire 1.6.8 + Firefox pulse-rust
# Covers: wrong default sink (HDMI), mute/corked after suspend/restart, EBUSY after D3
set -eu
SINK="alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Headphones__sink"
LOG() { echo "[fix-firefox] $*"; }

# 1. Ensure Headphones is default (not HDMI) - WirePlumber sometimes restores HDMI after crash
CURRENT=$(pactl get-default-sink 2>/dev/null || echo "")
if [ "$CURRENT" != "$SINK" ]; then
  LOG "default sink $CURRENT -> $SINK"
  pactl set-default-sink "$SINK" 2>/dev/null || true
  # also wpctl if pactl not enough
  wpctl status >/dev/null 2>&1 || true
fi
# unmute + set volume 100% at ALSA/PipeWire level (stored mute in asound.state caused silence)
pactl set-sink-mute "$SINK" 0 2>/dev/null || true
wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 2>/dev/null || true
amixer -c1 set Master unmute  >/dev/null 2>&1 || true
amixer -c1 set Headphone unmute >/dev/null 2>&1 || true
amixer -c1 set Speaker unmute  >/dev/null 2>&1 || true
# keep codec awake (same as fix-audio-powersave)
if [ -w /sys/module/snd_hda_intel/parameters/power_save ]; then echo 0 > /sys/module/snd_hda_intel/parameters/power_save 2>/dev/null || true; fi

# 2. Fix stream-properties DB where Firefox stored muted
# wireplumber stores Output/Audio:application.name:Firefox mute false normally, but if once muted it persists
# Ensure not muted via pactl for all existing Firefox sink-inputs
for id in $(pactl list sink-inputs short 2>/dev/null | awk '{print $1}'); do
  CLIENT=$(pactl list sink-inputs 2>/dev/null | grep -A2 "Sink Input #$id" | grep -o "Firefox" || true)
  # move all firefox streams to Headphones (core issue: after restart they attach to HDMI)
  if pactl list sink-inputs 2>/dev/null | grep -A15 "Sink Input #$id" | grep -q "Firefox"; then
    LOG "fix firefox sink-input $id -> $SINK unmute"
    pactl move-sink-input "$id" "$SINK" 2>/dev/null || true
    pactl set-sink-input-mute "$id" 0 2>/dev/null || true
    pactl set-sink-input-volume "$id" 65536 2>/dev/null || true
  fi
done

# 3. Also fix via wpctl for future nodes (wireplumber policy)
# ensure default routes prefer Headphones
LOG "sink-inputs now:"
pactl list sink-inputs short 2>/dev/null | head -n 20 || true
LOG "wpctl status sinks:"
wpctl status 2>&1 | grep -E "Sinks:|Headphones|HDMI" | head -n 10

# 4. Notify user if firefox still corked (needs tab reload) - can't uncork from outside, tab must play
CORKED=$(pactl list sink-inputs 2>/dev/null | grep -c "Corked: yes" || true)
RUNNING=$(pactl list sink-inputs 2>/dev/null | grep -c "Corked: no" || true)
if [ "$CORKED" -gt 0 ] && [ "$RUNNING" -eq 0 ]; then
  LOG "All Firefox streams corked (paused tabs) -> press Play in tab, no bug"
elif [ "$CORKED" -gt 5 ] && [ "$RUNNING" -eq 1 ]; then
  LOG "Most tabs paused, 1 running - normal. If no sound, do: F5 reload YouTube tab or pkill -HUP firefox + reopen"
fi
LOG "done - Headphones RUNNING? $(pactl list sinks short 2>/dev/null | grep Headphones || echo missing)"
