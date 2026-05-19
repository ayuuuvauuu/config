#!/usr/bin/env bash
# ~/.config/sway/scripts/sway-notify-daemon.sh
set -euo pipefail

# Store child PIDs to kill them gracefully on exit
declare -a CHILD_PIDS=()

log() {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] $*"
}

cleanup() {
    log "Stopping notify daemon and children..."
    for pid in "${CHILD_PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            kill -TERM "$pid" 2>/dev/null || true
        fi
    done
    wait 2>/dev/null || true
    log "Daemon stopped."
    exit 0
}

# Trap signals for graceful shutdown
trap cleanup SIGINT SIGTERM EXIT

# ---------------------------------------------------------
# 1. Media Monitor
# ---------------------------------------------------------
media_monitor() {
    log "Starting media monitor..."

    # Event-driven: playerctl waits for dbus events. No polling!
    playerctl metadata --follow \
        --format "{{status}}|{{title}}|{{artist}}|{{album}}" 2>/dev/null | \
    while IFS='|' read -r status title artist album; do
        if [[ "$status" == "Playing" ]]; then
            # 'x-canonical-private-synchronous' replaces existing media notifications
            notify-send -h string:x-canonical-private-synchronous:media \
                -i audio-x-generic \
                "🎵 ${title:-Unknown}" "${artist:-Unknown}${album:+\n💽 $album}"
        fi
    done &
    CHILD_PIDS+=($!)
}

# ---------------------------------------------------------
# 2. Battery Monitor
# ---------------------------------------------------------
battery_monitor() {
    log "Starting battery monitor..."

    local notified_20=0
    local notified_10=0
    local notified_5=0

    check_battery() {
        for bat_path in /sys/class/power_supply/BAT*; do
            [[ -f "$bat_path/capacity" && -f "$bat_path/status" ]] || continue

            local status capacity
            read -r status < "$bat_path/status" || continue
            read -r capacity < "$bat_path/capacity" || continue

            if [[ "$status" == "Discharging" ]]; then
                if (( capacity <= 5 && notified_5 == 0 )); then
                    notify-send -u critical -i battery-empty "Battery Critical" "Battery is at ${capacity}%! Suspend imminent."
                    notified_5=1 notified_10=1 notified_20=1
                elif (( capacity <= 10 && notified_10 == 0 )); then
                    notify-send -u critical -i battery-low "Battery Low" "Battery is at ${capacity}%."
                    notified_10=1 notified_20=1
                elif (( capacity <= 20 && notified_20 == 0 )); then
                    notify-send -u normal -i battery-caution "Battery Warning" "Battery is at ${capacity}%."
                    notified_20=1
                fi
            else
                notified_20=0 notified_10=0 notified_5=0
            fi
            break # Only process the first battery found
        done
    }

    # Run check once at startup
    check_battery

    # Event-driven: trigger check on power state changes.
    upower --monitor 2>/dev/null | while read -r _; do
        check_battery
    done &
    CHILD_PIDS+=($!)
}

# ---------------------------------------------------------
# Initialization
# ---------------------------------------------------------
media_monitor
battery_monitor

log "Daemon is running..."

while true; do
    wait -n || true
    log "Warning: A background monitor exited unexpectedly."
    sleep 5
done
