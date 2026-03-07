#!/usr/bin/env bash

time=$(date "+%Y-%m-%d_%H-%M-%S")
dir="$(xdg-user-dir)/Pictures/Screenshots"
file="Screenshot_${time}.png"
path="$dir/$file"

mkdir -p "$dir"

notify_done() {
    notify-send "Screenshot saved" "$path"
}

countdown() {
    for sec in $(seq "$1" -1 1); do
        notify-send "Screenshot" "Taking shot in $sec..."
        sleep 1
    done
}

shotnow() {
    grim - | tee "$path" | wl-copy
    notify_done
}

shot5() {
    countdown 5
    grim - | tee "$path" | wl-copy
    notify_done
}

shot10() {
    countdown 10
    grim - | tee "$path" | wl-copy
    notify_done
}

shotarea() {
    grim -g "$(slurp)" - | tee "$path" | wl-copy
    notify_done
}

shotactive() {
    read pos size <<< $(swaymsg -t get_tree | jq -r '
        .. | select(.focused? == true) |
        "\(.rect.x),\(.rect.y) \(.rect.width)x\(.rect.height)"')

    grim -g "$pos $size" - | tee "$path" | wl-copy
    notify_done
}

shotswappy() {
    grim -g "$(slurp)" - | tee "$path" | swappy -f -
    notify_done
}

case "$1" in
    --now) shotnow ;;
    --in5) shot5 ;;
    --in10) shot10 ;;
    --area) shotarea ;;
    --active) shotactive ;;
    --swappy) shotswappy ;;
    *) echo "Options: --now --in5 --in10 --area --active --swappy" ;;
esac

exit 0
