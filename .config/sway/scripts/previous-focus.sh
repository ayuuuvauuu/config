#!/usr/bin/env bash
# Switch to the previously focused Sway container, including containers on
# another workspace.
#
# Sway does not expose a built-in "last focused window" command.  The daemon
# below listens for focus/workspace changes and records container IDs.  IDs are
# validated before use, so closed windows and stale state are harmless.

set -u

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/sway-focus-history-${UID}.txt"
STATE_LOCK="${XDG_RUNTIME_DIR:-/tmp}/sway-focus-history-${UID}.lock"
DAEMON_LOCK="${XDG_RUNTIME_DIR:-/tmp}/sway-focus-history-${UID}.daemon.lock"
MAX_HISTORY=32

current_container() {
    swaymsg -t get_tree -r 2>/dev/null |
        jq -r '.. | objects | select(.focused == true and (.type == "con" or .type == "floating_con")) | .id' |
        head -n 1
}

container_exists() {
    [[ "$1" =~ ^[0-9]+$ ]] || return 1
    swaymsg -t get_tree -r 2>/dev/null |
        jq -e --argjson id "$1" '.. | objects | select(.id? == $id) | .id' >/dev/null
}

with_state_lock() {
    exec 8>"$STATE_LOCK"
    flock -w 5 8
}

release_state_lock() {
    flock -u 8 2>/dev/null || true
}

record_current() {
    local current="$1" tmp
    [[ "$current" =~ ^[0-9]+$ ]] || return 0

    with_state_lock || return 0
    touch "$STATE_FILE" || { release_state_lock; return 0; }
    tmp=$(mktemp "${STATE_FILE}.XXXXXX") || { release_state_lock; return 0; }
    {
        printf '%s\n' "$current"
        awk -v current="$current" -v max="$MAX_HISTORY" '
            $0 ~ /^[0-9]+$/ && $0 != current && !seen[$0]++ {
                print
                if (++count >= max) exit
            }
        ' "$STATE_FILE"
    } >"$tmp"
    mv -f "$tmp" "$STATE_FILE"
    release_state_lock
}

daemon() {
    # Keep only one listener, including across Sway config reloads.
    exec 9>"$DAEMON_LOCK"
    flock -n 9 || exit 0

    mkdir -p "${STATE_FILE%/*}" 2>/dev/null || true
    record_current "$(current_container)"

    while swaymsg -t subscribe -m '["window", "workspace"]' 2>/dev/null |
        while IFS= read -r _event; do
            # Querying the tree instead of trusting event payloads handles
            # workspace changes, floating windows, and container nesting.
            record_current "$(current_container)"
        done
    do
        # Reconnect if Sway briefly restarts or the IPC stream is interrupted.
        sleep 1
    done
}

previous() {
    local current target tmp
    current=$(current_container)
    [[ "$current" =~ ^[0-9]+$ ]] || exit 0

    with_state_lock || exit 0
    [[ -r "$STATE_FILE" ]] || { release_state_lock; exit 0; }
    while IFS= read -r target; do
        [[ "$target" =~ ^[0-9]+$ && "$target" != "$current" ]] || continue
        if container_exists "$target"; then
            if swaymsg "[con_id=$target] focus" >/dev/null 2>&1; then
                release_state_lock
                exit 0
            fi
        fi

        # Drop closed windows while looking for the next usable entry.
        tmp=$(mktemp "${STATE_FILE}.XXXXXX") || { release_state_lock; exit 0; }
        awk -v stale="$target" '$0 != stale' "$STATE_FILE" >"$tmp"
        mv -f "$tmp" "$STATE_FILE"
    done <"$STATE_FILE"
    release_state_lock
}

case "${1:-}" in
    --daemon) daemon ;;
    --previous) previous ;;
    *)
        printf 'usage: %s --daemon|--previous\n' "$0" >&2
        exit 2
        ;;
esac
