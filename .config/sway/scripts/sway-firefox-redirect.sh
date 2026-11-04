#!/usr/bin/env bash
# Open Firefox with at most 2 windows per workspace, current workspace first.
# Only moves windows opened by this press; never switches workspace.

set -u

# Serialize presses so they don't grab the same slots.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/sway-firefox.lock"
flock -w 30 9 || exit 0

cur=$(swaymsg -t get_workspaces -r | jq -r '.[] | select(.focused) | .num')
[ -n "$cur" ] && [ "$cur" -ge 1 ] || exit 0

# Map new window ids to the first free slots: current, forward, wrap,
# then new workspaces after the highest. Missing workspaces count as empty.
# shellcheck disable=SC2016  # this is a jq program, not shell
assign='
  def is_ff: ((.app_id // "") + " " + (.window_properties.class // "")) | test("firefox"; "i");
  [.. | objects | select(.type? == "workspace" and .name? != "__i3_scratch")
   | {num, n: ([.. | objects | select(is_ff and (.id as $i | $before | index($i)))] | length)}]
  | map(select(.num >= 1)) as $found
  | (($found | map(.num) | max) // 0) as $max
  | [range(1; $max + 1) as $n
     | {num: $n, n: ([$found[] | select(.num == $n) | .n] | add // 0)}] as $ws
  | ([$ws[] | select(.num >= $cur)] + [$ws[] | select(.num < $cur)]) as $order
  | [$order[] as $w | range(0; 2 - $w.n) | $w.num] as $free
  | [range(0; ($new | length)) as $k | $max + 1 + (($k / 2) | floor)] as $more
  | ($free + $more)[0:($new | length)] as $slots
  | [range(0; ($new | length)) | "\($new[.]) \($slots[.])"][]
'

# Snapshot existing windows; these must not be touched.
before=$(swaymsg -t get_tree -r | jq -c '
  def is_ff: ((.app_id // "") + " " + (.window_properties.class // "")) | test("firefox"; "i");
  [.. | objects | select(is_ff) | .id] | sort
')
[ -n "$before" ] || before='[]'

if [ "${1:-}" = "--dry-run" ]; then
    swaymsg -t get_tree -r |
        jq -r --argjson before "$before" --argjson cur "$cur" --argjson new '[0]' "$assign" |
        awk '{print "target workspace: " $2}'
    exit 0
fi

was_running=0
pgrep -x firefox >/dev/null 2>&1 && was_running=1

# 9>&- keeps Firefox from inheriting the lock fd.
firefox --new-window >/dev/null 2>&1 9>&- &

# Move new windows as they appear. Cold start can restore a session, so keep
# watching for 2s of quiet; an already-running Firefox opens just one window.
seen='[]'
moved=''
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
        assignments=$(swaymsg -t get_tree -r |
            jq -r --argjson before "$before" --argjson cur "$cur" --argjson new "$seen" "$assign")
        while read -r id target; do
            [ -z "$id" ] && continue
            case " $moved " in *" $id "*) continue ;; esac
            [ "$target" -eq "$cur" ] || {
                swaymsg "[con_id=$id] move window to workspace number $target" >/dev/null
                swaymsg "workspace number $cur" >/dev/null
            }
            moved="$moved $id"
        done <<< "$assignments"
        [ "$was_running" -eq 1 ] && break
    fi
    [ "$seen" != "[]" ] && [ $((SECONDS - last)) -ge 2 ] && break
    sleep 0.2
done
