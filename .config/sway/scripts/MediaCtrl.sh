#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Playerctl (Notifications handled by sway-notify-daemon)

# Find best target: prefer cmus/spotify, then YouTube-Music/Spotify-Web in browser,
# then any browser, skip other players entirely.
get_target() {
    local browser_fallback=""
    local music_url_match=""

    while IFS= read -r p; do
        case "$p" in
            cmus|spotify)
                echo "$p"
                return 0
                ;;
            firefox*|chrome*|chromium*)
                [[ -z "$browser_fallback" ]] && browser_fallback="$p"
                url=$(playerctl --player="$p" metadata xesam:url 2>/dev/null)
                if [[ "$url" == *"music.youtube.com"* || "$url" == *"open.spotify.com"* ]]; then
                    music_url_match="$p"
                fi
                ;;
        esac
    done < <(playerctl -l 2>/dev/null)

    [[ -n "$music_url_match" ]] && echo "$music_url_match" && return 0
    [[ -n "$browser_fallback" ]] && echo "$browser_fallback" && return 0
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
