#!/usr/bin/env bash
# hack-fbi.sh — four-pane "I'm doing something very serious" tmux cover.
# Top-left: bruteforce   Top-right: uv
# Bottom-left: rkhunter  Bottom-right: memdump
#
# Panes open one at a time (HACK_FBI_DELAY seconds apart, default 1).
#
# Usage: hack-fbi.sh [session-name]   (default: hack-fbi)
# Env:   HACK_FBI_DETACH=1  build the session but don't attach/switch.
#        HACK_FBI_DELAY=2   seconds between panes.
set -euo pipefail

SESSION="${1:-hack-fbi}"
WINDOW="hack"
DELAY="${HACK_FBI_DELAY:-1}"

genact="$(command -v genact || true)"
if [[ -z $genact ]]; then
  echo "hack-fbi.sh: genact not found — install it (pacman -S genact, or cargo install genact)" >&2
  exit 1
fi

# Fresh session every time, so a re-run doesn't pile up panes.
tmux kill-session -t "$SESSION" 2>/dev/null || true

# -P -F '#{pane_id}' gives us stable targets regardless of base-index settings.
tl="$(tmux new-session -d -s "$SESSION" -n "$WINDOW" -P -F '#{pane_id}' "$genact -m bruteforce")"

tmux set-option -t "$SESSION" -w pane-border-status top
# Explicit format: the tmux 3.7 default appends clickable zoom/kill control
# ranges (rendered as stray "z"/"x" text on terminals that don't hide them).
tmux set-option -t "$SESSION" -w pane-border-format \
  '#{?pane_active,#[reverse],}#{pane_index}: #{pane_title}#[default]'
tmux select-pane -t "$tl" -T "bruteforce"
tmux select-pane -t "$tl"

# Open the remaining panes one at a time so they show up on screen
# progressively instead of all at once.
build_panes() {
  local tr bl br
  for _ in 1 2 3; do
    sleep "$DELAY"
    tmux has-session -t "$SESSION" 2>/dev/null || exit 0

    if [[ -z ${tr:-} ]]; then
      tr="$(tmux split-window -h -t "$tl" -P -F '#{pane_id}' "$genact -m uv")"
      tmux select-pane -t "$tr" -T "uv"
    elif [[ -z ${bl:-} ]]; then
      bl="$(tmux split-window -v -t "$tl" -P -F '#{pane_id}' "$genact -m rkhunter")"
      tmux select-pane -t "$bl" -T "rkhunter"
    else
      br="$(tmux split-window -v -t "$tr" -P -F '#{pane_id}' "$genact -m memdump")"
      tmux select-pane -t "$br" -T "memdump"
    fi
  done

  tmux select-pane -t "$tl" 2>/dev/null || true
}

if [[ -n ${HACK_FBI_DETACH:-} ]]; then
  build_panes
  exit 0
fi

# Build in the background so we can attach/switch immediately and watch
# the panes open live.
build_panes &
disown 2>/dev/null || true

if [[ -n ${TMUX:-} ]]; then
  tmux switch-client -t "$SESSION"
elif [[ -t 0 ]]; then
  tmux attach -t "$SESSION"
else
  # No controlling terminal (e.g. launched from an agent/script): borrow the
  # client that's already attached, if there's exactly one.
  mapfile -t clients < <(tmux list-clients -F '#{client_tty}' 2>/dev/null)
  if [[ ${#clients[@]} -eq 1 ]]; then
    tmux switch-client -c "${clients[0]}" -t "$SESSION"
  else
    echo "hack-fbi.sh: no tty — session '$SESSION' built; attach with: tmux attach -t $SESSION" >&2
  fi
fi
