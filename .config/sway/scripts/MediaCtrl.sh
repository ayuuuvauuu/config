#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Playerctl (Notifications handled by sway-notify-daemon)

PLAYERS="cmus,spotify,firefox,chrome,chromium"

# Play the next track
play_next() {
    playerctl --player="$PLAYERS" next
}

# Play the previous track
play_previous() {
    playerctl --player="$PLAYERS" previous
}

# Toggle play/pause
toggle_play_pause() {
    playerctl --player="$PLAYERS" play-pause
}

# Stop playback
stop_playback() {
    playerctl --player="$PLAYERS" stop
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
