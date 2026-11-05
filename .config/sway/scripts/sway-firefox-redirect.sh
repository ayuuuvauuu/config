#!/usr/bin/env bash
# Open Firefox with at most 2 windows per workspace, starting after the current
# workspace. Only moves windows opened by this press and never focuses them.

set -u

# Serialize presses so they don't grab the same slots.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/sway-firefox.lock"
flock -w 30 9 || exit 0

tree=$(swaymsg -t get_tree -r)
[ -n "$tree" ] || exit 0

cur=$(swaymsg -t get_workspaces -r | jq -r '.[] | select(.focused) | .num')
[ -n "$cur" ] && [ "$cur" -ge 1 ] || exit 0

# Map new window ids in pairs to genuinely unused workspace numbers after the
# current workspace. Existing workspaces containing any window are skipped;
# missing workspace numbers count as unused. The plan is based on the initial
# tree so windows arriving one at a time still stay in the same pair.
# shellcheck disable=SC2016  # this is a jq program, not shell
assign='
  def is_window: ((.type? == "con" or .type? == "floating_con")
                  and ((.pid? != null) or (.app_id? != null) or (.window? != null)));
  [.. | objects | select(.type? == "workspace" and .name? != "__i3_scratch")
   | {num, n: ([.. | objects | select(is_window)] | length)}]
  | map(select(.num >= 1)) as $found
  | ((($found | map(.num)) + [$cur] | max) // $cur) as $max
  | [range(1; $max + 1) as $n
     | {num: $n, n: ([$found[] | select(.num == $n) | .n] | add // 0)}] as $ws
  | [$ws[] | select(.num > $cur and .n == 0) | .num] as $free
  | [range(0; ($new | length)) as $i
     | ($i / 2 | floor) as $pair
     | ($free[$pair] // ($max + 1 + ($pair - ($free | length)))) as $target
     | "\($new[$i]) \($target)"][]
'

# Snapshot existing windows; these must not be touched.
before=$(jq -c '
  def is_ff: ((.app_id // "") + " " + (.window_properties.class // "")) | test("firefox"; "i");
  [.. | objects | select(is_ff) | .id] | sort
' <<< "$tree")
[ -n "$before" ] || before='[]'

if [ "${1:-}" = "--dry-run" ]; then
    jq -r --argjson cur "$cur" --argjson new '[0]' "$assign" <<< "$tree" |
        awk '{print "target workspace: " $2}'
    exit 0
fi

was_running=0
pgrep -x firefox >/dev/null 2>&1 && was_running=1

# Firefox can request activation when it is already running. Disable that
# behavior only for this launch; the user's configured mode is restored on exit.
activation_changed=0
restore_activation() {
    [ "$activation_changed" -eq 1 ] || return 0
    swaymsg "focus_on_window_activation focus" >/dev/null 2>&1 || true
}
trap restore_activation EXIT INT TERM
swaymsg "focus_on_window_activation none" >/dev/null || exit 0
activation_changed=1

# 9>&- keeps Firefox from inheriting the lock fd.
firefox --new-window >/dev/null 2>&1 9>&- &

# Move new windows as they appear. Cold start can restore a session, so keep
# watching for 2s of quiet; an already-running Firefox opens just one window.
seen='[]'
moved='[]'
last=$SECONDS
end=$((SECONDS + 20))

while [ "$SECONDS" -lt "$end" ]; do
    now=$(swaymsg -t get_tree -r | jq -c --argjson before "$before" '
      def is_ff: ((.app_id // "") + " " + (.window_properties.class // "")) | test("firefox"; "i");
      [.. | objects | select(is_ff and (.id as $id | ($before | index($id) | not))) | .id] | sort
    ')
    if [ "$now" != "[]" ] && [ "$now" != "$seen" ]; then
        seen=$now
        last=$SECONDS
    fi
    if [ "$seen" != "[]" ]; then
        assignments=$(jq -r --argjson cur "$cur" --argjson new "$seen" "$assign" <<< "$tree")
        while read -r id target; do
            [ -z "$id" ] && continue
            if jq -e --arg id "$id" 'index($id) != null' <<< "$moved" >/dev/null 2>&1; then
                continue
            fi
            swaymsg "[con_id=$id] move window to workspace number $target" >/dev/null
            moved=$(jq -c --argjson moved "$moved" --arg id "$id" '$moved + [$id]')
        done <<< "$assignments"
        [ "$was_running" -eq 1 ] && break
    fi
    [ "$seen" != "[]" ] && [ $((SECONDS - last)) -ge 2 ] && break
    sleep 0.2
done
