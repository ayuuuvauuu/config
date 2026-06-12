#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Playerctl (Notifications handled by sway-notify-daemon)

# Priority: yt-music > cmus > mpv > spotify > yt > vlc > skip
get_target() {
    local best=""
    local best_priority=-1

    while IFS= read -r p; do
        local priority=0

        case "$p" in
            cmus)   priority=5 ;;
            mpv)    priority=4 ;;
            spotify) priority=3 ;;
            vlc)    priority=1 ;;
            firefox*|chrome*|chromium*)
                url=$(playerctl --player="$p" metadata xesam:url 2>/dev/null)
                case "$url" in
                    *music.youtube.com*) priority=6 ;;
                    *open.spotify.com*)  priority=3 ;;
                    *youtube.com*)       priority=2 ;;
                esac
                ;;
        esac

        if (( priority > best_priority )); then
            best="$p"
            best_priority=$priority
        fi
    done < <(playerctl -l 2>/dev/null)

    [[ -n "$best" ]] && echo "$best" && return 0
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
