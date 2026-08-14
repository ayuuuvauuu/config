#!/bin/sh
IFACE="wlan0"
FREQ=$(iw dev "$IFACE" link | sed -n 's/.*freq: \([0-9]*\).*/\1/p')
if [ -z "$FREQ" ]; then
    CHANNEL=6
elif [ "$FREQ" -ge 5000 ]; then
    CHANNEL=$(( (FREQ - 5000) / 5 ))
else
    CHANNEL=$(( (FREQ - 2407) / 5 ))
fi
sudo create_ap -c "$CHANNEL" "$IFACE" "$IFACE" victus password