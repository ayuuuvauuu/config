#!/bin/bash
~/.config/sway/scripts/sway-auto-redirect.sh &
R=$!
firefox "$@" &
F=$!
wait $F 2>/dev/null
kill $R 2>/dev/null
