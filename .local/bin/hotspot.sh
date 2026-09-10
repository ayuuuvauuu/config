#!/bin/sh
set -eu

IFACE=${IFACE:-wlan0}
SSID=${SSID:-victus}
PASSPHRASE=${PASSPHRASE:-password}
CHANNEL=${CHANNEL:-}
UPSTREAM_IFACE=${UPSTREAM_IFACE:-}

if ! command -v create_ap >/dev/null 2>&1; then
    printf 'hotspot.sh: create_ap is not installed\n' >&2
    exit 1
fi

if ! command -v iw >/dev/null 2>&1; then
    printf 'hotspot.sh: iw is not installed\n' >&2
    exit 1
fi

if ! iw dev "$IFACE" info >/dev/null 2>&1; then
    printf 'hotspot.sh: interface not found: %s\n' "$IFACE" >&2
    exit 1
fi

# Validate passphrase early (create_ap would fail later with cryptic hostapd error)
if [ -n "$PASSPHRASE" ] && [ "${#PASSPHRASE}" -lt 8 ]; then
    printf 'hotspot.sh: passphrase must be 8..63 characters (got %d)\n' "${#PASSPHRASE}" >&2
    exit 1
fi

if [ -z "$CHANNEL" ]; then
    FREQ=$(iw dev "$IFACE" link 2>/dev/null | sed -n 's/.*freq: \([0-9][0-9]*\).*/\1/p' | head -n 1)
    if [ -z "$FREQ" ]; then
        CHANNEL=6
    elif [ "$FREQ" -eq 2484 ]; then
        CHANNEL=14
    elif [ "$FREQ" -lt 2484 ]; then
        CHANNEL=$(( (FREQ - 2407) / 5 ))
    elif [ "$FREQ" -ge 4910 ] && [ "$FREQ" -le 4980 ]; then
        CHANNEL=$(( (FREQ - 4000) / 5 ))
    elif [ "$FREQ" -lt 5950 ]; then
        CHANNEL=$(( (FREQ - 5000) / 5 ))
    elif [ "$FREQ" -le 7115 ]; then
        # 6 GHz band: 5955 MHz -> channel 1, 7115 -> 233
        CHANNEL=$(( (FREQ - 5950) / 5 ))
    else
        # 60 GHz or unknown - fall back to current band default and let
        # create_ap / hostapd validate. Mirrors create_ap's ieee80211_frequency_to_channel.
        CHANNEL=6
    fi
    # guard against FREQ=5950 yielding 0 (not a real channel)
    if [ "$CHANNEL" = "0" ]; then CHANNEL=6; fi
fi

# CHANNEL must be a positive integer; quote-safe but fail fast instead of
# passing garbage to `create_ap -c`.
case "$CHANNEL" in
    ''|*[!0-9]*|0)
        printf 'hotspot.sh: invalid CHANNEL: %s\n' "$CHANNEL" >&2
        exit 1
        ;;
esac

# No manual systemd-resolved / iptables / nft handling here.
# create_ap runs dnsmasq on 5353 with iptables REDIRECT --to-ports 5353
# and leaves systemd-resolved (127.0.0.53 stub, resolv.conf mode foreign)
# intact, so host + client DNS keeps working. It also manages NAT/
# forwarding internally and cleans up on exit - no trap needed (exec replaces shell).

# UPSTREAM_IFACE handling:
#   unset/empty -> share internet via same wifi iface (virtual ap0, original behavior)
#   "none"      -> isolated AP with no internet (`create_ap -n`), no NAT
#   <iface>     -> share internet from that upstream iface
if [ "${UPSTREAM_IFACE:-}" = "none" ]; then
    exec sudo create_ap -n -c "$CHANNEL" "$IFACE" "$SSID" "$PASSPHRASE"
fi

# Default to same-interface sharing (create_ap creates virtual AP via nl80211).
# This is explicitly supported by create_ap ("You can create an AP with the same
# interface...") and restores the pre-regression `wlan0 wlan0` behavior.
UPSTREAM_IFACE=${UPSTREAM_IFACE:-$IFACE}

if [ ! -d "/sys/class/net/$UPSTREAM_IFACE" ]; then
    printf 'hotspot.sh: upstream interface not found: %s\n' "$UPSTREAM_IFACE" >&2
    exit 1
fi

exec sudo create_ap -c "$CHANNEL" "$IFACE" "$UPSTREAM_IFACE" "$SSID" "$PASSPHRASE"
