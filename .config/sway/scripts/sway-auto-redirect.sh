#!/bin/bash

THRESHOLD=2

cleanup() {
    pkill -P $$ swaymsg
    exit 0
}
trap cleanup SIGINT SIGTERM

while read -r line; do
    change=$(echo "$line" | jq -r '.change // empty')
    [ "$change" != "new" ] && continue

    con_id=$(echo "$line" | jq -r '.container.id // empty')
    app_id=$(echo "$line" | jq -r '.container.app_id // empty')
    window_class=$(echo "$line" | jq -r '.container.window_properties.class // empty')

    app="${app_id:-$window_class}"
    case "$app" in
        *[fF]irefox*) ;;
        *) continue ;;
    esac

    cur=$(swaymsg -t get_workspaces -r | jq -r '.[] | select(.focused) | .num')
    [ -z "$cur" ] && continue

    target=$(swaymsg -t get_tree -r | jq -r --argjson cur "$cur" --argjson limit "$THRESHOLD" '
        [.. | select(.type? == "workspace" and .name? != "__i3_scratch")
         | { num: .num,
             count: [.. | select(.app_id? | test("firefox"; "i") or .window_properties?.class? | test("firefox"; "i"))] | length }]
        | sort_by(.num)
        | . as $all
        | ($all[] | select(.num == $cur)) as $cur_ws
        | if $cur_ws.count <= $limit then empty
          else (($all | map(select(.num > $cur and .count < $limit))) + ($all | map(select(.num < $cur and .count < $limit)) ) | first | .num // empty)
          end
    ')

    if [ -z "$target" ]; then
        target=$((cur + 1))
    fi
    swaymsg "[con_id=$con_id] move window to workspace number $target" >/dev/null 2>&1
done < <(swaymsg -m -t SUBSCRIBE '["window"]')
