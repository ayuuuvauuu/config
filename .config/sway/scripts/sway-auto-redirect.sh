#!/bin/bash

THRESHOLD=2
declare -A COUNT

cleanup() {
    pkill -P $$ swaymsg
    exit 0
}
trap cleanup SIGINT SIGTERM

while read -r line; do
    change=$(echo "$line" | jq -r '.change // empty')
    [ "$change" != "new" ] && continue

    app_id=$(echo "$line" | jq -r '.container.app_id // empty')
    window_class=$(echo "$line" | jq -r '.container.window_properties.class // empty')
    con_id=$(echo "$line" | jq -r '.container.id // empty')

    app="${app_id:-$window_class}"
    case "$app" in
        *[fF]irefox*) ;;
        *) continue ;;
    esac

    cur=$(swaymsg -t get_workspaces -r | jq -r '.[] | select(.focused) | .num')
    [ -z "$cur" ] && continue

    COUNT[$cur]=$(( ${COUNT[$cur]} + 1 ))

    if [ "${COUNT[$cur]}" -gt "$THRESHOLD" ]; then
        moved=false
        for ((i = cur + 1; i <= 8; i++)); do
            [ "${COUNT[$i]:-0}" -lt "$THRESHOLD" ] || continue
            swaymsg "[con_id=$con_id] move window to workspace number $i" >/dev/null 2>&1
            moved=true; break
        done
        if ! $moved && [ "$cur" -eq 8 ]; then
            for ((i = 1; i <= 7; i++)); do
                [ "${COUNT[$i]:-0}" -lt "$THRESHOLD" ] || continue
                swaymsg "[con_id=$con_id] move window to workspace number $i" >/dev/null 2>&1
                break
            done
        fi
    fi
done < <(swaymsg -m -t SUBSCRIBE '["window"]')
