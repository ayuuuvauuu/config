#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##

# For Hyprlock

file=".background.png"
dir="$(xdg-user-dir)/Pictures/Screenshots"
cd ${dir} && grim - | tee "$file"
pidof hyprlock || hyprlock -q 
