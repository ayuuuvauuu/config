#!/bin/sh
# vesktop-toggle.sh — floating Vesktop on the sway scratchpad
#
#   vesktop-toggle.sh toggle   show if hidden, hide if shown (mod+d)
#   vesktop-toggle.sh kill     close Vesktop window + process (mod+shift+d)
#
# How it works:
#   - for_window (in sway config) forces every Vesktop window floating,
#     sized and centered.
#   - SHOW = `move workspace current` (+ focus). This is deliberately NOT
#     `scratchpad show`: on this Vesktop/Electron build, scratchpad-show
#     succeeds yet leaves the window hidden, while a workspace move forces
#     a remap the client honors. Works from anywhere: scratchpad-hidden,
#     other workspace, or fresh window.
#   - HIDE = `move scratchpad` for fresh windows (adopts them), plain
#     `scratchpad show` (which hides a shown scratchpad window) after that.
#   - Workspace switches never move the window; mod+d on another workspace
#     pulls it there.
#   - If no Vesktop window exists, we launch it (single-instance: safe even
#     if a tray process is still alive, so mod+d can never spawn dupes).

APP_ID="vesktop"
CMD="vesktop"

notify() {
    command -v notify-send >/dev/null 2>&1 && notify-send "Vesktop" "$1"
}

# Pick the "main" Vesktop window: prefer focused, then visible, then any
# (e.g. a hidden scratchpad window). Ignores the transient updater popup.
# Prints "<con_id> <scratchpad_state> <visible>" or nothing.
find_win() {
    swaymsg -t get_tree | jq -r --arg id "$APP_ID" '
        [.. | objects | select(.app_id == $id and .name != "Vesktop Updater")]
        | (map(select(.focused)) + map(select(.visible)) + .)
        | first // empty
        | "\(.id) \(.scratchpad_state) \(.visible)"
    '
}

win_ws() {
    # Containing workspace of a container. NOTE: .workspace is null for
    # scratchpad-managed windows (even shown ones), so walk up to the
    # workspace node instead. Prints the name, or nothing.
    swaymsg -t get_tree | jq -r --argjson c "$1" '
        [.. | objects | select(.type == "workspace")
         | select([.. | objects | .id?] | index($c)) | .name] | first // empty
    '
}

toggle_vesktop() {
    info=$(find_win)
    if [ -z "$info" ]; then
        if any_vesktop_proc; then
            # Already running (likely tray-only, no window): do not launch a
            # second instance or notify; just ask it to show its window.
            swaymsg "exec $CMD" >/dev/null
            exit 0
        fi
        # Not running -> launch.
        # for_window floats + centers it; next toggle adopts it to scratchpad.
        notify "launching Vesktop..."
        swaymsg "exec $CMD" >/dev/null
        exit 0
    fi

    con=${info%% *}
    rest=${info#* }
    state=${rest%% *}
    visible=${rest##* }
    cur=$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused) | .name')

    if [ "$visible" = "true" ]; then
        ws=$(win_ws "$con")
        if [ -n "$ws" ] && [ "$ws" != "$cur" ]; then
            # Shown on another workspace: pull it here (no hide cycle).
            swaymsg "[con_id=$con] move workspace current; [con_id=$con] focus" >/dev/null
        elif [ "$state" = "none" ]; then
            # Fresh window shown here: adopt into scratchpad (hides it).
            swaymsg "[con_id=$con] move scratchpad" >/dev/null
        else
            # Scratchpad window shown here: hide it back.
            swaymsg "[con_id=$con] scratchpad show" >/dev/null
        fi
    else
        # Hidden (scratchpad) or fresh window elsewhere: show it here.
        swaymsg "[con_id=$con] move workspace current; [con_id=$con] focus" >/dev/null
    fi
}

any_vesktop_proc() {
    # Vesktop runs as Electron; match its app bundle on the command line.
    pgrep -f '[v]esktop/app.asar' >/dev/null 2>&1
}

kill_vesktop() {
    # 1. close the window(s); Vesktop retreats to the tray, so follow through:
    swaymsg "[app_id=\"$APP_ID\"] kill" >/dev/null 2>&1
    # 2. SIGTERM the app (main + children by cmdline)...
    pkill -TERM -f '[v]esktop/app.asar' >/dev/null 2>&1
    sleep 2
    # 3. ...then SIGKILL stragglers (tray apps often shrug off TERM).
    if any_vesktop_proc; then
        pkill -KILL -f '[v]esktop/app.asar' >/dev/null 2>&1
        sleep 1
    fi
    pkill -f '[v]esktop.*[C]rashpad' >/dev/null 2>&1
    if any_vesktop_proc; then
        notify "kill failed - still running"
    else
        notify "killed"
    fi
}

case "${1:-toggle}" in
    kill|k|close|quit) kill_vesktop ;;
    *) toggle_vesktop ;;
esac
