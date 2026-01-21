#!/usr/bin/env bash

RID=4242

playerctl --follow metadata --format '{{mpris:trackid}}' |
while read -r trackid; do
    [[ "$trackid" == "$last" ]] && continue
    last="$trackid"

    sleep 0.1

    title=$(playerctl metadata title 2>/dev/null)
    artist=$(playerctl metadata artist 2>/dev/null)

    [[ -z "$title" || -z "$artist" ]] && continue

    notify-send -u low -r "$RID" "playing:" "$title\tby $artist"
done
