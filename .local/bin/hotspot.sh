#!/bin/sh
set -eu

IFACE=${IFACE:-wlan0}
SSID=${SSID:-victus}
PASSPHRASE=${PASSPHRASE:-password}
CHANNEL=${CHANNEL:-}
UPSTREAM_IFACE=${UPSTREAM_IFACE:-}
# Poll interval (seconds) for uplink-change watcher. Override: HOTSPOT_POLL=5 hotspot.sh
HOTSPOT_POLL=${HOTSPOT_POLL:-3}
# Set HOTSPOT_NO_RESTART=1 to disable auto-restart loop (single create_ap run, old behavior).
HOTSPOT_NO_RESTART=${HOTSPOT_NO_RESTART:-0}
# Remember whether CHANNEL / DHCP_DNS were explicitly requested (vs auto-detect each restart).
CHANNEL_REQ=${CHANNEL:-}
DHCP_DNS_REQ=${DHCP_DNS:-}

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

# --- helpers (host-untouched: only reads iw / resolv.conf / resolvectl) ---
auto_channel() {
    # Echo wifi channel for iface $1 from current `iw link` freq. Falls back to 6.
    _f=$(iw dev "$1" link 2>/dev/null | sed -n 's/.*freq: \([0-9][0-9]*\).*/\1/p' | head -n 1)
    if [ -z "${_f:-}" ]; then
        printf '6\n'
    elif [ "$_f" -eq 2484 ]; then
        printf '14\n'
    elif [ "$_f" -lt 2484 ]; then
        printf '%s\n' "$(( (_f - 2407) / 5 ))"
    elif [ "$_f" -ge 4910 ] && [ "$_f" -le 4980 ]; then
        printf '%s\n' "$(( (_f - 4000) / 5 ))"
    elif [ "$_f" -lt 5950 ]; then
        printf '%s\n' "$(( (_f - 5000) / 5 ))"
    elif [ "$_f" -le 7115 ]; then
        # 6 GHz band: 5955 MHz -> channel 1, 7115 -> 233
        _c=$(( (_f - 5950) / 5 ))
        if [ "$_c" = "0" ]; then _c=6; fi
        printf '%s\n' "$_c"
    else
        # 60 GHz or unknown - fall back and let create_ap / hostapd validate.
        printf '6\n'
    fi
    unset _f _c
}

valid_channel() {
    case "$1" in
        ''|*[!0-9]*|0) return 1 ;;
        *) return 0 ;;
    esac
}

auto_dns() {
    # Echo "IP[,IP]" for DHCP DNS: real uplink (bypass 127.0.0.53 stub), else public.
    _d=""
    if [ -r /run/systemd/resolve/resolv.conf ]; then
        _d=$(awk '/^nameserver /{print $2}' /run/systemd/resolve/resolv.conf 2>/dev/null \
            | grep -vE '^127\.|^::1' | grep -v ':' | paste -sd "," -)
    fi
    if [ -z "$_d" ] && command -v resolvectl >/dev/null 2>&1; then
        _d=$(resolvectl status 2>/dev/null \
            | awk '/DNS Servers:/{for(i=3;i<=NF;i++) print $i}' \
            | grep -vE '^127\.' | grep -v ':' | head -n 2 | paste -sd "," -)
    fi
    if [ -z "$_d" ]; then
        _d="1.1.1.1,8.8.8.8"
    else
        case "$_d" in
            *,*) ;;
            *) _d="${_d},1.1.1.1" ;;
        esac
        _d=$(printf "%s" "$_d" | tr ',' '\n' | head -n 2 | paste -sd "," -)
    fi
    printf '%s\n' "$_d"
    unset _d
}

uplink_id() {
    # Stable ID for STA uplink on iface $1: "BSSID|SSID|FREQ" or "disconnected".
    # Used to detect B -> C switches. Read-only, no system changes.
    _id=$(iw dev "$1" link 2>/dev/null \
        | sed -n 's/.*Connected to \([^ ]*\).*/\1/p; s/.*SSID: \(.*\)/\1/p; s/.*freq: \([0-9][0-9]*\).*/\1/p' \
        | paste -sd '|' -)
    if [ -z "$_id" ]; then
        printf 'disconnected\n'
    else
        printf '%s\n' "$_id"
    fi
    unset _id
}

resolve_channel() {
    if [ -n "$CHANNEL_REQ" ]; then
        printf '%s\n' "$CHANNEL_REQ"
    else
        auto_channel "$1"
    fi
}

resolve_dns() {
    if [ -n "$DHCP_DNS_REQ" ]; then
        printf '%s\n' "$DHCP_DNS_REQ"
    else
        auto_dns
    fi
}

# Validate explicit CHANNEL early (auto mode validated per-restart instead).
if [ -n "$CHANNEL_REQ" ]; then
    if ! valid_channel "$CHANNEL_REQ"; then
        printf 'hotspot.sh: invalid CHANNEL: %s\n' "$CHANNEL_REQ" >&2
        exit 1
    fi
fi

# DNS fix for ERR_NAME_NOT_RESOLVED — host-untouched (no resolv.conf / resolved changes).
#
# Root cause: create_ap runs dnsmasq on 5353 and iptables REDIRECTs clients'
# queries for 192.168.12.1:53 -> 5353. By default dnsmasq reads /etc/resolv.conf
# for upstream. On this host /etc/resolv.conf is the systemd-resolved stub
#   nameserver 127.0.0.53   (resolv.conf mode: foreign, see `resolvectl status`)
# while the real uplink is in /run/systemd/resolve/resolv.conf:
#   nameserver 192.168.29.1
# dnsmasq treats 127.0.0.53 as local and has no valid upstream, so all client
# DNS forwarded via the gateway fails → phone shows ERR_NAME_NOT_RESOLVED,
# while host itself works (host uses resolved's per-link DNS, not /etc/resolv.conf).
#
# Fix without touching the host: advertise a working DNS directly via DHCP
# option 6 (--dhcp-dns via resolve_dns()), so clients query it via NAT instead
# of relying on dnsmasq's broken upstream. Leaves systemd-resolved,
# /etc/resolv.conf, iptables/nft and host forwarding untouched — only the DHCP
# answer to clients changes. Respects DHCP_DNS env if set (e.g. DHCP_DNS=gateway).
#
# No manual systemd-resolved / iptables / nft handling here.
# create_ap manages NAT/forwarding internally and cleans up on exit.

usage() {
    printf 'Usage:\n' >&2
    printf '  hotspot.sh                     start hotspot (auto-restart on uplink change)\n' >&2
    printf '  hotspot.sh switch <SSID> [pass]  switch laptop wifi B -> C while hotspot runs\n' >&2
    printf '  hotspot.sh stop                stop running hotspot\n' >&2
    printf '  hotspot.sh status              show AP + uplink status\n' >&2
    printf 'Env: IFACE SSID PASSPHRASE CHANNEL UPSTREAM_IFACE DHCP_DNS HOTSPOT_POLL HOTSPOT_NO_RESTART=1\n' >&2
}

# --- subcommands (must run before UPSTREAM defaulting) ---
if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] || [ "${1:-}" = "help" ]; then
    usage
    exit 0
fi

if [ "${1:-}" = "status" ]; then
    echo "--- create_ap ---"
    sudo create_ap --list-running 2>&1 || true
    echo "--- uplink ($IFACE) ---"
    iw dev "$IFACE" link 2>&1 | head -n 5 || true
    echo "--- uplink id: $(uplink_id "${UPSTREAM_IFACE:-$IFACE}") ---"
    exit 0
fi

if [ "${1:-}" = "stop" ]; then
    exec sudo create_ap --stop "$IFACE"
fi

if [ "${1:-}" = "switch" ]; then
    # Switch laptop STA B -> C while hotspot runs, without touching host DNS/config.
    # Why needed: single radio (managed+AP requires #channels <= 1, see `iw list`).
    # AP is pinned to B's channel, so GNOME/nmcli switch to C on another channel
    # fails while AP holds the radio ("stuck at B"). Fix: briefly stop AP to free
    # the radio, switch STA, the running hotspot.sh loop then auto-restarts AP on
    # C's channel with fresh DNS. Stop is transient; create_ap cleans up itself.
    NEW_SSID=${2:-}
    NEW_PASS=${3:-}
    if [ -z "$NEW_SSID" ]; then
        printf 'hotspot.sh switch: missing SSID\nUsage: hotspot.sh switch <SSID> [password]\n' >&2
        exit 1
    fi
    if ! command -v nmcli >/dev/null 2>&1; then
        printf 'hotspot.sh switch: nmcli not found\n' >&2
        exit 1
    fi
    _up=${UPSTREAM_IFACE:-$IFACE}
    echo "hotspot.sh: freeing radio (stopping AP on $IFACE)..."
    sudo create_ap --stop "$IFACE" >/dev/null 2>&1 || true
    sleep 2
    echo "hotspot.sh: connecting $_up to '$NEW_SSID'..."
    if [ -n "$NEW_PASS" ]; then
        nmcli device wifi connect "$NEW_SSID" password "$NEW_PASS" ifname "$_up"
    else
        nmcli device wifi connect "$NEW_SSID" ifname "$_up"
    fi
    unset _up
    echo "hotspot.sh: switched. If hotspot.sh is running in another terminal it will auto-restart;"
    echo "hotspot.sh: otherwise run hotspot.sh now."
    exit 0
fi

if [ $# -gt 0 ]; then
    printf 'hotspot.sh: unknown arg: %s\n' "$1" >&2
    usage
    exit 1
fi

# UPSTREAM_IFACE handling:
#   unset/empty -> share internet via same wifi iface (virtual ap0, original behavior)
#   "none"      -> isolated AP with no internet (`create_ap -n`), no NAT
#   <iface>     -> share internet from that upstream iface
if [ "${UPSTREAM_IFACE:-}" = "none" ]; then
    # For isolated AP, --dhcp-dns is not needed; keep minimal.
    _ch=$(resolve_channel "$IFACE")
    if ! valid_channel "$_ch"; then
        printf 'hotspot.sh: invalid CHANNEL: %s\n' "$_ch" >&2
        exit 1
    fi
    exec sudo create_ap -n -c "$_ch" "$IFACE" "$SSID" "$PASSPHRASE"
fi

# Default to same-interface sharing (create_ap creates virtual AP via nl80211).
UPSTREAM_IFACE=${UPSTREAM_IFACE:-$IFACE}

if [ ! -d "/sys/class/net/$UPSTREAM_IFACE" ]; then
    printf 'hotspot.sh: upstream interface not found: %s\n' "$UPSTREAM_IFACE" >&2
    exit 1
fi

# Single-shot modes: different-phy upstream (no channel pinning) or explicit opt-out.
# Host-untouched: one create_ap run, it cleans up NAT/forwarding on exit.
if [ "$UPSTREAM_IFACE" != "$IFACE" ] || [ "$HOTSPOT_NO_RESTART" = "1" ]; then
    _ch=$(resolve_channel "$UPSTREAM_IFACE")
    if ! valid_channel "$_ch"; then
        printf 'hotspot.sh: invalid CHANNEL: %s\n' "$_ch" >&2
        exit 1
    fi
    _dns=$(resolve_dns)
    exec sudo create_ap --dhcp-dns "$_dns" -c "$_ch" "$IFACE" "$UPSTREAM_IFACE" "$SSID" "$PASSPHRASE"
fi

# --- same-radio loop: wlan0 STA + ap0 AP must share one channel (#channels <= 1) ---
# Problem you hit: connected to B, start hotspot -> AP pinned to B's channel.
# Try to switch STA to C on another channel via GNOME -> driver refuses
# (radio busy on B's channel) -> "stuck at B".
# Fix, still host-untouched:
#   * run create_ap in background, poll uplink_id() every $HOTSPOT_POLL sec;
#   * same-channel B->C roams succeed -> detect change -> `create_ap --stop` ->
#     restart AP on new channel/DNS (2s drop, clients re-DHCP);
#   * cross-channel B->C via GNOME still fails (hardware limit, no software can
#     do 2 channels on 1 radio) -> use `hotspot.sh switch C` in 2nd terminal,
#     which stops AP first, switches STA, loop restarts AP automatically.
# Nothing persistent is written: no resolv.conf / resolved / NM profile edits.
if ! command -v nmcli >/dev/null 2>&1; then
    printf 'hotspot.sh: warning: nmcli not found, switch helper disabled\n' >&2
fi
sudo -v || exit 1

AP_PID=""
loop_cleanup() {
    echo "" >&2
    echo "hotspot.sh: stopping..." >&2
    if [ -n "${AP_PID:-}" ] && kill -0 "$AP_PID" 2>/dev/null; then
        sudo create_ap --stop "$IFACE" >/dev/null 2>&1 || true
        wait "$AP_PID" 2>/dev/null || true
    else
        sudo create_ap --stop "$IFACE" >/dev/null 2>&1 || true
    fi
    exit 130
}
trap loop_cleanup INT TERM

FAIL_COUNT=0
while :; do
    CUR_CH=$(resolve_channel "$UPSTREAM_IFACE")
    if ! valid_channel "$CUR_CH"; then
        printf 'hotspot.sh: invalid CHANNEL: %s\n' "$CUR_CH" >&2
        exit 1
    fi
    CUR_DNS=$(resolve_dns)
    START_ID=$(uplink_id "$UPSTREAM_IFACE")
    echo "hotspot.sh: uplink $START_ID ch $CUR_CH dns $CUR_DNS -> AP '$SSID' on $IFACE" >&2
    echo "hotspot.sh: to change wifi run in another terminal: hotspot.sh switch <SSID>" >&2

    sudo create_ap --dhcp-dns "$CUR_DNS" -c "$CUR_CH" "$IFACE" "$UPSTREAM_IFACE" "$SSID" "$PASSPHRASE" &
    AP_PID=$!
    START_TS=$(date +%s)

    # Watch uplink while AP lives. wait/kill tests are exempt from `set -e`.
    while kill -0 "$AP_PID" 2>/dev/null; do
        sleep "$HOTSPOT_POLL" 2>/dev/null || sleep 3
        if ! kill -0 "$AP_PID" 2>/dev/null; then
            break
        fi
        CUR_ID=$(uplink_id "$UPSTREAM_IFACE")
        if [ "$CUR_ID" != "$START_ID" ]; then
            echo "hotspot.sh: uplink changed ($START_ID -> $CUR_ID), restarting AP..." >&2
            sudo create_ap --stop "$IFACE" >/dev/null 2>&1 || true
            break
        fi
    done

    wait "$AP_PID" 2>/dev/null || true
    AP_PID=""
    END_TS=$(date +%s)
    if [ $((END_TS - START_TS)) -lt 10 ]; then
        FAIL_COUNT=$((FAIL_COUNT + 1))
    else
        FAIL_COUNT=0
    fi
    if [ "$FAIL_COUNT" -ge 3 ]; then
        printf 'hotspot.sh: AP exited 3x in <10s, giving up (check passphrase/channel/dns)\n' >&2
        exit 1
    fi
    sleep 2
done
