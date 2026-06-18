#!/bin/bash

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
    [ -z "$cur" ] && continue

    cur_count=$(swaymsg -t get_tree -r | jq -r --arg app "$app" --argjson cur "$cur" '
        [.. | select(.type? == "workspace" and .num == $cur)
         | [.. | select(.app_id? == $app or .window_properties?.class? == $app)] | length]
        | first // 0
    ')

    # Current workspace still has room (count includes the new window)
    [ "$cur_count" -le "$THRESHOLD" ] && continue

    # Find next workspace with room — only forward, no wrap
    target=$(swaymsg -t get_tree -r | jq -r --arg app "$app" --argjson cur "$cur" --argjson limit "$THRESHOLD" '
        ([.. | select(.type? == "workspace" and .name? != "__i3_scratch" and .num != $cur)
          | { num: .num, count: [.. | select(.app_id? == $app or .window_properties?.class? == $app)] | length }]
         | sort_by(.num)
         | map(select(.num > $cur and .count < $limit))
         | first | .num // empty
    ')

    [ -z "$target" ] && continue
    swaymsg "[con_id=$con_id] move window to workspace number $target" >/dev/null 2>&1
done < <(swaymsg -m -t SUBSCRIBE '["window"]')
