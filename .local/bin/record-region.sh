#!/bin/sh
# POSIX-compliant region recording script with desktop audio

set -e

# --- DEPENDENCY CHECK ---
MISSING_DEPS=""

if ! command -v gpu-screen-recorder >/dev/null 2>&1; then
    MISSING_DEPS="gpu-screen-recorder $MISSING_DEPS"
fi

if ! command -v slurp >/dev/null 2>&1; then
    MISSING_DEPS="slurp $MISSING_DEPS"
fi

# We need pactl to automatically find your audio output
if ! command -v pactl >/dev/null 2>&1; then
    MISSING_DEPS="pactl $MISSING_DEPS"
fi

if [ -n "$MISSING_DEPS" ]; then
    echo "ERROR: Missing required dependencies:$MISSING_DEPS" >&2
    echo "Please install them via your package manager." >&2
    exit 1
fi

# --- DIRECTORY SANITY CHECK ---
TARGET_DIR="$HOME/Videos"
if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p "$TARGET_DIR"
fi

# --- AUDIO DETECT EDGE CASE ---
# Fetch the default sound output sink name
DEFAULT_SINK=$(pactl get-default-sink 2>/dev/null || true)
AUDIO_ARG=""

if [ -n "$DEFAULT_SINK" ]; then
    # Standard format for recording system sound output via PipeWire/PulseAudio
    AUDIO_ARG="-a $DEFAULT_SINK.monitor"
else
    echo "WARNING: Could not detect default audio sink. Recording video only." >&2
fi

# --- REGION SELECTION ---
if ! REGION=$(slurp -f "%wx%h+%x+%y" 2>/dev/null); then
    echo "Selection cancelled by user."
    exit 0
fi

if [ -z "$REGION" ]; then
    echo "ERROR: Received empty geometry from slurp." >&2
    exit 1
fi

# Generate timestamped filename
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
OUTPUT_FILE="$TARGET_DIR/screen_record_$TIMESTAMP.mp4"

# --- EXECUTION ---
echo "Recording started for region: $REGION"
if [ -n "$AUDIO_ARG" ]; then
    echo "Audio device: $DEFAULT_SINK.monitor"
fi
echo "Saving to: $OUTPUT_FILE"
echo "Press Ctrl+C in this terminal window to stop recording."

# Launch the recording process with audio arguments safely unquoted if empty
exec gpu-screen-recorder -w region -region "$REGION" $AUDIO_ARG -f 60 -o "$OUTPUT_FILE"
