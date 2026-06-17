#!/bin/bash

# sway-auto-redirect.sh
# Distribute windows so no workspace has more than THRESHOLD from the same app.
# Windows go to the first workspace (1-8) with room.

THRESHOLD=2
MONITORED_APPS=()

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
    [ -z "$app" ] && continue

    if [ ${#MONITORED_APPS[@]} -gt 0 ]; then
        monitored=false
        for m in "${MONITORED_APPS[@]}"; do
            [[ "$app" == "$m" ]] && { monitored=true; break; }
        done
        $monitored || continue
    fi

    cur=$(swaymsg -t get_workspaces -r | jq -r '.[] | select(.focused) | .num')

    target=$(swaymsg -t get_tree -r | jq -r --arg app "$app" --argjson cur "$cur" --argjson limit "$THRESHOLD" '
        ([.. | select(.type? == "workspace" and .name? != "__i3_scratch")
          | { num: .num, count: [.. | select(.app_id? == $app or .window_properties?.class? == $app)] | length }]
         | sort_by(.num)) as $all
        | ($all | map(select(.num >= $cur))) + ($all | map(select(.num < $cur)))
        | map(select(.count < $limit))
        | first | .num // empty
    ')

    [ -z "$target" ] && continue

    if [ "$target" != "$cur" ]; then
        swaymsg "[con_id=$con_id] move window to workspace number $target" >/dev/null 2>&1
    fi
done < <(swaymsg -m -t SUBSCRIBE '["window"]')
