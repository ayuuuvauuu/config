#!/bin/bash

# sway-auto-redirect.sh
# Automatically redirect excess windows from the same app to the next
# numbered workspace (current + 1, wrapping after 8 to 1).
# Configure THRESHOLD and MONITORED_APPS below.

THRESHOLD=3
MONITORED_APPS=()

declare -A WINDOW_COUNTS

cleanup() {
    pkill -P $$ swaymsg
    exit 0
}
trap cleanup SIGINT SIGTERM

next_workspace() {
    swaymsg -t get_workspaces -r | jq -r '
        [.[] | select(.focused == true) | .num][0] as $cur
        | if $cur == 8 then 1 elif $cur then $cur + 1 else 4 end
        | tostring
    '
}

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

    WINDOW_COUNTS["$app"]=$(( ${WINDOW_COUNTS["$app"]} + 1 ))
    count=${WINDOW_COUNTS["$app"]}

    if [ "$count" -gt "$THRESHOLD" ]; then
        target=$(next_workspace)
        swaymsg "[con_id=$con_id] move window to workspace number $target" >/dev/null 2>&1
    fi
done < <(swaymsg -m -t SUBSCRIBE '["window"]')
