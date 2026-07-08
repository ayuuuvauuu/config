#!/bin/bash

# Path to track the state
STATE_FILE="/tmp/hyprwhspr_state"

if [ ! -f "$STATE_FILE" ]; then
    # --- FIRST PRESS: START ---
    wl-copy -c
    hyprwhspr-rs record start
    echo "recording" > "$STATE_FILE"
else
    # --- SECOND PRESS: STOP ---
    hyprwhspr-rs record stop
    # Paste using Ctrl + Shift + V everywhere
    wtype -M ctrl -M shift v -m shift -m ctrl
    # Remove state file
    rm "$STATE_FILE"
fi
