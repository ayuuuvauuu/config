#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Playerctl (Notifications handled by sway-notify-daemon)

# Play the next track
play_next() {
    playerctl next
}

# Play the previous track
play_previous() {
    playerctl previous
}

# Toggle play/pause
toggle_play_pause() {
    playerctl play-pause
}

# Stop playback
stop_playback() {
    playerctl stop
    # Optional: Keep the stop notification since the daemon only tracks "Playing" state
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
