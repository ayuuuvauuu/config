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
# 2. Battery & AC Monitor
# ---------------------------------------------------------
battery_monitor() {
    log "Starting battery monitor..."

    local notified_20=0
    local notified_10=0
    local notified_5=0
    local notified_ac_powersave=0

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

    check_ac_powersave() {
        for ac_path in /sys/class/power_supply/{ADP,AC}*; do
            [[ -f "$ac_path/online" ]] || continue
            
            local online
            read -r online < "$ac_path/online" || continue
            
            if [[ "$online" == "1" ]]; then
                if (( notified_ac_powersave == 0 )); then
                    notified_ac_powersave=1
                    
                    # Fork a check that waits 3s (allows auto-cpufreq time to switch if it's on auto)
                    (
                        sleep 3
                        # Re-read to ensure it's still plugged in
                        read -r current_online < "$ac_path/online" 2>/dev/null || exit 0
                        [[ "$current_online" == "1" ]] || exit 0
                        
                        local gov="unknown" no_turbo="unknown"
                        [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]] && read -r gov < /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
                        [[ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]] && read -r no_turbo < /sys/devices/system/cpu/intel_pstate/no_turbo
                        
                        if [[ "$gov" == "powersave" && "$no_turbo" == "1" ]]; then
                            notify-send -u normal -t 8000 -i dialog-warning "Performance Limited" "AC connected, but CPU is in Powersave (Turbo OFF). Don't forget to restore performance!"
                        elif [[ "$gov" == "powersave" ]]; then
                            notify-send -u normal -t 8000 -i dialog-warning "Performance Limited" "AC connected, but CPU governor is forced to Powersave."
                        elif [[ "$no_turbo" == "1" ]]; then
                            notify-send -u normal -t 8000 -i dialog-warning "Performance Limited" "AC connected, but Turbo Boost is turned off."
                        fi
                    ) &
                fi
            else
                notified_ac_powersave=0
            fi
            break # Only process the first AC adapter found
        done
    }

    # Run checks once at startup
    check_battery
    check_ac_powersave

    # Event-driven: trigger checks on power state changes.
    upower --monitor 2>/dev/null | while read -r _; do
        check_battery
        check_ac_powersave
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
