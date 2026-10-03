#!/usr/bin/env bash

set -euo pipefail

# ==============================================================================
# CONFIGURATION
# ==============================================================================
MONITOR=$(hyprctl monitors all | awk '/Monitor eDP/ {print $2}' | head -n 1)
MONITOR=${MONITOR:-eDP-1} # Fallback if not found
RES="1920x1080"      # Display resolution
HIGH_HZ="144"        # Performance refresh rate
LOW_HZ="60"          # Power-saving refresh rate (fallback to safest hardware-supported minimum)
SCALE="1.20"         # Monitor scale (non-negotiable)
STATE_FILE="$HOME/.cache/hypr_college_mode"

# ==============================================================================
# COMMAND CHECKS
# ==============================================================================
# Helper to check if a command exists without failing the script due to 'set -e'
cmd_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Ensure critical dependencies exist
if ! cmd_exists hyprctl; then
    echo "Error: hyprctl not found! Is Hyprland running?" >&2
    exit 1
fi

# ==============================================================================
# TOGGLE LOGIC
# ==============================================================================
if [ ! -f "$STATE_FILE" ]; then
    # ==============================
    # STATE A: POWER-SAVING (COLLEGE)
    # ==============================
    touch "$STATE_FILE"

    # Save current brightness
    if cmd_exists brightnessctl; then
        echo "BRIGHTNESS=$(brightnessctl get)" >> "$STATE_FILE"
        brightnessctl set 30% >/dev/null
    fi

    # Save bluetooth state (0 = was unblocked, 1 = was already blocked)
    if cmd_exists rfkill; then
        if rfkill list bluetooth | grep -q "Soft blocked: no"; then
            echo "BT_BLOCKED=0" >> "$STATE_FILE"
        else
            echo "BT_BLOCKED=1" >> "$STATE_FILE"
        fi
        rfkill block bluetooth
    fi

    # 1. Lower refresh rate
    hyprctl eval "hl.monitor({ output = '$MONITOR', mode = '${RES}@${LOW_HZ}', scale = ${SCALE} })" >/dev/null


    # 3. Set CPU to power-saver profile
    if cmd_exists powerprofilesctl; then
        powerprofilesctl set power-saver >/dev/null
    fi

    # 4. Send desktop notification
    if cmd_exists notify-send; then
        notify-send -u low "majdoor mode"
    fi

else
    # ==============================
    # STATE B: PERFORMANCE (DEFAULT)
    # ==============================
    
    # Read saved states
    if [ -f "$STATE_FILE" ]; then
        # shellcheck disable=SC1090
        source "$STATE_FILE"
        rm -f "$STATE_FILE"
    fi

    # Restore brightness
    if cmd_exists brightnessctl && [ -n "${BRIGHTNESS:-}" ]; then
        brightnessctl set "$BRIGHTNESS" >/dev/null
    fi

    # Restore bluetooth (only unblock if it was previously unblocked)
    if cmd_exists rfkill && [ "${BT_BLOCKED:-0}" = "0" ]; then
        rfkill unblock bluetooth
    fi

    # 1. Restore high refresh rate
    hyprctl eval "hl.monitor({ output = '$MONITOR', mode = '${RES}@${HIGH_HZ}', scale = ${SCALE} })" >/dev/null


    # 3. Restore CPU governor to balanced
    if cmd_exists powerprofilesctl; then
        powerprofilesctl set balanced >/dev/null
    fi

    # 4. Send desktop notification
    if cmd_exists notify-send; then
        notify-send -u low "masti mode"
    fi
fi
