#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Playerctl (Notifications handled by sway-notify-daemon)

# Priority: yt-music > cmus > mpv > spotify > yt > vlc
# Firefox exposes one MPRIS per browser, so tabs can't be
# distinguished. Best-effort: if YouTube Music URL is detected,
# target that instance directly; otherwise fall back to the list.
get_target() {
    local browsers=""

    while IFS= read -r p; do
        case "$p" in
            firefox*|chrome*|chromium*)
                url=$(playerctl --player="$p" metadata xesam:url 2>/dev/null)
                if [[ "$url" == *"music.youtube.com"* ]]; then
                    echo "$p"
                    return 0
                fi
                browsers+="$p,"
                ;;
        esac
    done < <(playerctl -l 2>/dev/null)

    browsers="${browsers%,}"
    # playerctl --player picks first running player from the list
    echo "cmus,mpv,spotify,${browsers},vlc"
}

# Play the next track
play_next() {
    local target
    target=$(get_target) || return
    playerctl --player="$target" next
}

# Play the previous track
play_previous() {
    local target
    target=$(get_target) || return
    playerctl --player="$target" previous
}

# Toggle play/pause
toggle_play_pause() {
    local target
    target=$(get_target) || return
    playerctl --player="$target" play-pause
}

# Stop playback
stop_playback() {
    local target
    target=$(get_target) || return
    playerctl --player="$target" stop
    music_icon="$HOME/.config/swaync/icons/music.png"
    notify-send -e -u low -i "$music_icon" "Playback Stopped"
}

# Get media control action from command line argument
case "$1" in
    "--nxt")
        play_next
        ;;
    "--prv")
        play_previous
        ;;
    "--pause")
        toggle_play_pause
        ;;
    "--stop")
        stop_playback
        ;;
    *)
        echo "Usage: $0 [--nxt|--prv|--pause|--stop]"
        exit 1
        ;;
esac
