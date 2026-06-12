#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Playerctl (Notifications handled by sway-notify-daemon)

# Find the first player that matches our allowed list and content filter
get_target() {
    while IFS= read -r p; do
        case "$p" in
            cmus|spotify)
                echo "$p"
                return 0
                ;;
            firefox*|chrome*|chromium*)
                url=$(playerctl --player="$p" metadata xesam:url 2>/dev/null)
                case "$url" in
                    *music.youtube.com*|*open.spotify.com*)
                        echo "$p"
                        return 0
                        ;;
                esac
                ;;
        esac
    done < <(playerctl -l 2>/dev/null)
    return 1
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
