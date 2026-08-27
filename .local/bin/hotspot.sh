#!/bin/sh
IFACE="wlan0"
SUBNET="192.168.12.0/24"
RESOLVED_WAS_ACTIVE=0

cleanup() {
    echo "Stopping hotspot..."
    sudo killall create_ap hostapd dnsmasq 2>/dev/null
    sudo ip link del ap0 2>/dev/null
    if [ "$RESOLVED_WAS_ACTIVE" -eq 1 ]; then
        sudo systemctl start systemd-resolved 2>/dev/null
    fi
    echo "Cleaned up."
}
trap cleanup EXIT INT TERM

free_port53() {
    if ss -ulnp | grep -q ':53 '; then
        if systemctl is-active --quiet systemd-resolved; then
            RESOLVED_WAS_ACTIVE=1
            sudo systemctl stop systemd-resolved 2>/dev/null
            echo "Freed port 53 from systemd-resolved"
        fi
    fi
}

setup_forwarding() {
    if [ "$(cat /proc/sys/net/ipv4/ip_forward)" = "0" ]; then
        sudo sysctl -w net.ipv4.ip_forward=1 > /dev/null
        echo "Enabled IP forwarding"
    fi
    if ! sudo iptables -t nat -C POSTROUTING -s "$SUBNET" -o "$IFACE" -j MASQUERADE 2>/dev/null; then
        sudo iptables -t nat -A POSTROUTING -s "$SUBNET" -o "$IFACE" -j MASQUERADE
        echo "Added NAT masquerade rule"
    fi
    if ! sudo iptables -C FORWARD -i ap0 -o "$IFACE" -j ACCEPT 2>/dev/null; then
        sudo iptables -A FORWARD -i ap0 -o "$IFACE" -j ACCEPT
        sudo iptables -A FORWARD -i "$IFACE" -o ap0 -m state --state RELATED,ESTABLISHED -j ACCEPT
        echo "Added iptables forwarding rules"
    fi
    if sudo nft list chain inet filter forward >/dev/null 2>&1; then
        if ! sudo nft list chain inet filter forward | grep -q "ap0"; then
            sudo nft insert rule inet filter forward iifname "ap0" accept
            sudo nft insert rule inet filter forward iifname "$IFACE" oifname "ap0" ct state established,related accept
            echo "Added nftables forwarding rules"
        fi
    fi
}

FREQ=$(iw dev "$IFACE" link | sed -n 's/.*freq: \([0-9]*\).*/\1/p')
if [ -z "$FREQ" ]; then
    CHANNEL=6
elif [ "$FREQ" -ge 5000 ]; then
    CHANNEL=$(( (FREQ - 5000) / 5 ))
else
    CHANNEL=$(( (FREQ - 2407) / 5 ))
fi

free_port53
setup_forwarding
sudo create_ap -c "$CHANNEL" "$IFACE" "$IFACE" victus password
