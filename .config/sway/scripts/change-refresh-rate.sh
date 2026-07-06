#!/bin/bash

OUTPUT="eDP-1"

# Get current refresh rate safely
CURRENT_RATE=$(swaymsg -t get_outputs | jq -r ".[] | select(.name==\"$OUTPUT\") | .current_mode.refresh")

# Check if CURRENT_RATE is empty or not a number
if [[ -z "$CURRENT_RATE" || ! "$CURRENT_RATE" =~ ^[0-9]+$ ]]; then
    notify-send "⚠️ Failed to read refresh rate for $OUTPUT"
    exit 1
fi

# Toggle between 60Hz and 144Hz
if (( CURRENT_RATE < 100000 )); then
    swaymsg output "$OUTPUT" mode 1920x1080@144Hz
    notify-send "⚡ Switched to 144Hz"
else
    swaymsg output "$OUTPUT" mode 1920x1080@60Hz
    notify-send "🌙 Switched to 60Hz"
fi
