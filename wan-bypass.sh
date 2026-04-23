#!/bin/sh
WAN_IF="eth0"
WAN_BYPASS_GW="192.168.2.1"
WAN_BYPASS_IPS="10.10.10.2/32"

usage() {
    echo "Usage: $0 {on|off|status}"
    echo "  on     - Add WAN bypass routes"
    echo "  off    - Remove WAN bypass routes"
    echo "  status - Show current bypass routes"
    exit 1
}

bypass_on() {
    echo "[wan-bypass] started"

    # Wait for WAN IP
    while true; do
        ip -4 addr show dev "$WAN_IF" | grep -q "inet " && break
        echo "[wan-bypass] waiting for WAN IP on $WAN_IF..."
        sleep 1
    done

    echo "[wan-bypass] WAN IP ready"

    for ipcidr in $WAN_BYPASS_IPS; do
        ip route del "$ipcidr" via "$WAN_BYPASS_GW" 2>/dev/null
        ip route add "$ipcidr" via "$WAN_BYPASS_GW" 2>/dev/null && \
            echo "[wan-bypass] added: $ipcidr via $WAN_BYPASS_GW" || \
            echo "[wan-bypass] failed: $ipcidr via $WAN_BYPASS_GW"
    done

    echo "[wan-bypass] done"
}

bypass_off() {
    for ipcidr in $WAN_BYPASS_IPS; do
        ip route del "$ipcidr" via "$WAN_BYPASS_GW" 2>/dev/null && \
            echo "[wan-bypass] removed: $ipcidr via $WAN_BYPASS_GW" || \
            echo "[wan-bypass] not found: $ipcidr"
    done
    echo "[wan-bypass] done"
}

bypass_status() {
    echo "[wan-bypass] checking routes..."
    FOUND=0
    for ipcidr in $WAN_BYPASS_IPS; do
        RESULT=$(ip route get "${ipcidr%/*}" 2>/dev/null)
        if echo "$RESULT" | grep -q "via $WAN_BYPASS_GW"; then
            echo "[wan-bypass] active: $ipcidr via $WAN_BYPASS_GW"
            FOUND=1
        else
            echo "[wan-bypass] inactive: $ipcidr"
        fi
    done
    [ "$FOUND" -eq 0 ] && echo "[wan-bypass] no active bypass routes"
}

[ $# -ne 1 ] && usage

case "$1" in
    on)     bypass_on ;;
    off)    bypass_off ;;
    status) bypass_status ;;
    *)      usage ;;
esac
