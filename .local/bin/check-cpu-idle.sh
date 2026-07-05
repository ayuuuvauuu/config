#!/bin/bash
# cpu-check-idle.sh - show each CPU core's C-state via turbostat (MSR)

if ! command -v turbostat &>/dev/null; then
  echo "turbostat not found. Install it:"
  echo "  Arch:    sudo pacman -S linux-tools"
  echo "  Ubuntu:  sudo apt install linux-tools-common linux-tools-\$(uname -r)"
  echo "  Fedora:  sudo dnf install kernel-tools"
  exit 1
fi

sudo turbostat --quiet --show CPU,Busy%,POLL%,C1E%,C6%,C8%,C10% -i 1 sleep 1 2>&1 |
  tail -n +3 |
  while IFS=$'\t' read -r cpu busy poll c1e c6 c8 c10; do
    [ "$cpu" = "-" ] && continue
    for v in busy poll c1e c6 c8 c10; do
      val="${!v}"; val="${val%.*}"; [ -z "$val" ] && val=0
      eval "$v=$val"
    done
    best="C0"; best_val=$busy
    for pair in "POLL $poll" "C1E $c1e" "C6 $c6" "C8 $c8" "C10 $c10"; do
      val="${pair##* }"; name="${pair%% *}"
      (( val > best_val )) && { best_val=$val; best=$name; }
    done
    printf "%-6s %s\n" "cpu$cpu:" "$best"
  done
