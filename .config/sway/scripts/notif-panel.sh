#!/usr/bin/env bash
# notif-panel.sh — mako history viewer, zero resident cost
# Count mode (no args): prints Waybar JSON {text,tooltip,class}
# Panel mode (--panel): fuzzel GUI popup showing unread (makoctl list), fallback to history
set -euo pipefail

LIST="$(makoctl list -j 2>/dev/null || echo '[]')"
HIST="$(makoctl history -j 2>/dev/null || echo '[]')"
UNREAD="$(jq 'length' <<<"$LIST")"
SAVED="$(jq 'length' <<<"$HIST")"

if [[ "${1:-}" == "--panel" ]]; then
  if (( UNREAD > 0 )); then
    MENU="$(jq -r '.[] | "\(.summary // "no-summary") — \(.body // "" | tostring)"' <<<"$LIST")"
    TITLE="Unread ($UNREAD)"
  elif (( SAVED > 0 )); then
    MENU="$(jq -r '.[] | "\(.summary // "no-summary") — \(.body // "" | tostring)"' <<<"$HIST")"
    TITLE="History ($SAVED)"
  else
    notify-send "Notifications" "No notifications"
    exit 0
  fi
  echo "$MENU" | fuzzel --dmenu --prompt "$TITLE> " --lines 10 --width 60 >/dev/null || true
  exit 0
fi

# count mode for Waybar
if (( UNREAD > 0 )); then
  TIP="$(jq -r '.[] | "\(.summary // "")"' <<<"$LIST" | head -5 | paste -sd '\n' -)"
  jq -n --argjson n "$UNREAD" --arg tip "$TIP" \
    '{"text":" \($n)","tooltip":("Unread: \($n)\n" + $tip),"class":"notification"}'
elif (( SAVED > 0 )); then
  jq -n --argjson n "$SAVED" \
    '{"text":"","tooltip":("History: \($n) — click to view"),"class":"none"}'
else
  echo '{"text":"","tooltip":"No notifications","class":"none"}'
fi
