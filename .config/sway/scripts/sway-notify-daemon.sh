#!/usr/bin/env bash
# ~/.config/sway/scripts/sway-notify-daemon.sh
set -euo pipefail

# Create a named pipe (FIFO) in RAM
FIFO="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/sway-notify-fifo-$$"
mkfifo "$FIFO"

# Clean up FIFO and kill background binaries on exit
trap 'rm -f "$FIFO"; kill $(jobs -p) 2>/dev/null || true' EXIT

# Open FIFO for reading and writing so it never sends EOF
exec 3<> "$FIFO"

# Launch raw binaries directly into the FIFO (No Bash subshells created!)
stdbuf -oL playerctl --player=cmus,spotify,firefox,chrome,chromium metadata --follow --format "MEDIA|{{status}}|{{title}}|{{artist}}|{{album}}" >&3 2>/dev/null &
stdbuf -oL upower --monitor >&3 2>/dev/null &

notified_20=0
notified_10=0
notified_5=0

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
        break
    done
}

# Run check once at startup
check_battery

# Single blocking loop in the main bash process reads everything
while IFS='|' read -r col1 col2 col3 col4 col5 <&3; do
    if [[ "$col1" == "MEDIA" ]]; then
        if [[ "$col2" == "Playing" ]]; then
            notify-send -h string:x-canonical-private-synchronous:media \
                -i audio-x-generic \
                "${col3:-Unknown}" "${col4:-Unknown}"
        fi
    else
        # Any other text is an event from upower
        check_battery
    fi
done
