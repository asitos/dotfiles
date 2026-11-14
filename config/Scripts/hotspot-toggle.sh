#!/usr/bin/env bash
# ==============================================================================
# Hotspot Toggle Script
# Portable NetworkManager hotspot manager with dynamic interface detection
# and zero hardcoded credentials.
# ==============================================================================

set -u

CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/hotspot.env"
if [ -f "$CONFIG_FILE" ]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
fi

# Auto-detect default wireless interface if not specified
detect_wifi_iface() {
    local iface
    iface=$(nmcli -t -f DEVICE,TYPE device status 2>/dev/null | awk -F: '$2=="wifi"{print $1; exit}')
    echo "${iface:-wlan0}"
}

CON_NAME="${HOTSPOT_CON_NAME:-Hotspot}"
IFACE="${HOTSPOT_IFACE:-$(detect_wifi_iface)}"
SSID="${HOTSPOT_SSID:-"${USER:-user}-hotspot"}"

# Generate random secure 12-char password if none provided
generate_password() {
    tr -dc 'A-Za-z0-9' </dev/urandom | head -c 12
}

# Create profile if missing in NetworkManager
if ! nmcli -t -f NAME connection show | grep -Fxq "$CON_NAME"; then
    PASS="${HOTSPOT_PASS:-$(generate_password)}"

    # Save to user's local config file (gitignored) for persistence
    if [ ! -f "$CONFIG_FILE" ]; then
        mkdir -p "$(dirname "$CONFIG_FILE")"
        cat > "$CONFIG_FILE" <<EOF
# Hotspot Local Configuration (Auto-generated)
# Edit these variables to customize your hotspot. This file is gitignored.
HOTSPOT_CON_NAME="$CON_NAME"
HOTSPOT_IFACE="$IFACE"
HOTSPOT_SSID="$SSID"
HOTSPOT_PASS="$PASS"
EOF
        chmod 600 "$CONFIG_FILE"
    fi

    nmcli connection add type wifi ifname "$IFACE" con-name "$CON_NAME" autoconnect no ssid "$SSID" >/dev/null 2>&1
    nmcli connection modify "$CON_NAME" 802-11-wireless.mode ap
    nmcli connection modify "$CON_NAME" 802-11-wireless-security.key-mgmt wpa-psk
    nmcli connection modify "$CON_NAME" 802-11-wireless-security.psk "$PASS"
    nmcli connection modify "$CON_NAME" ipv4.method shared ipv6.method ignore
fi

is_active() {
    nmcli -t -f NAME connection show --active | grep -Fxq "$CON_NAME"
}

turn_on() {
    if is_active; then
        SSID=$(nmcli -s -g 802-11-wireless.ssid connection show "$CON_NAME" 2>/dev/null)
        notify-send -t 2500 "Hotspot" "Already active (${SSID:-$CON_NAME})" -h string:x-canonical-private-synchronous:hotspot
        return 0
    fi

    if nmcli connection up "$CON_NAME"; then
        SSID=$(nmcli -s -g 802-11-wireless.ssid connection show "$CON_NAME" 2>/dev/null)
        PASS=$(nmcli -s -g 802-11-wireless-security.psk connection show "$CON_NAME" 2>/dev/null)
        notify-send -t 4000 "Hotspot" "Active\nSSID: ${SSID:-$CON_NAME}\nPass: ${PASS:-[none]}" -h string:x-canonical-private-synchronous:hotspot
    else
        notify-send -u critical -t 3000 "Hotspot" "Failed to start" -h string:x-canonical-private-synchronous:hotspot
        return 1
    fi
}

turn_off() {
    if ! is_active; then
        notify-send -t 2000 "Hotspot" "Already inactive" -h string:x-canonical-private-synchronous:hotspot
        return 0
    fi

    if nmcli connection down "$CON_NAME"; then
        notify-send -t 2000 "Hotspot" "Deactivated" -h string:x-canonical-private-synchronous:hotspot
        nmcli device connect "$IFACE" >/dev/null 2>&1 &
    else
        notify-send -u critical -t 3000 "Hotspot" "Failed to stop" -h string:x-canonical-private-synchronous:hotspot
        return 1
    fi
}

case "${1:-toggle}" in
    on)
        turn_on
        ;;
    off)
        turn_off
        ;;
    status)
        if is_active; then
            echo "active"
        else
            echo "inactive"
        fi
        ;;
    toggle|*)
        if is_active; then
            turn_off
        else
            turn_on
        fi
        ;;
esac
