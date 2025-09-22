#!/bin/bash

# Set time-based temp for Hyprsunset
hour=$(date +%H)

if [ "$hour" -ge 20 ] || [ "$hour" -lt 7 ]; then
  # Night time: 8PM–6:59AM
  hyprsunset -t 3300k
else
  # Day time: 7AM–7:59PM
  hyprsunset -t 3300k
fi

