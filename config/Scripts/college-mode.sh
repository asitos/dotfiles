#!/usr/bin/env bash

# CONFIGURATION
MONITOR="eDP-2"
RES="1920x1080"
HIGH_HZ="144"
LOW_HZ="60"          # Most panels support 60Hz; 40 or 48 if your panel explicitly supports it
STATE_FILE="/tmp/hypr_college_mode"

if [ ! -f "$STATE_FILE" ]; then
    # ==============================
    # ENTER POWER-SAVING (COLLEGE) MODE
    # ==============================
    touch "$STATE_FILE"

    # 1. Lower refresh rate
    hyprctl keyword monitor "$MONITOR,$RES@$LOW_HZ,0x0,1"

    # 2. Disable Hyprland animations and blur/decorations
    hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword decoration:blur:enabled 0;\
        keyword decoration:drop_shadow 0;\
        keyword misc:vfr 1"

    # 3. Drop display brightness to a battery-friendly level (requires brightnessctl)
    command -v brightnessctl >/dev/null 2>&1 && brightnessctl set 30%

    # 4. Set CPU to power-saving governor (requires power-profiles-daemon or tlp)
    if command -v powerprofilesctl >/dev/null 2>&1; then
        powerprofilesctl set power-saver
    fi

    # 5. Optional: Send desktop notification (requires libnotify)
    command -v notify-send >/dev/null 2>&1 && notify-send -u low "Power Mode" "College Battery Saver: ON (60Hz, Effects Off)"

else
    # ==============================
    # RESTORE PERFORMANCE (DEFAULT) MODE
    # ==============================
    rm -f "$STATE_FILE"

    # 1. Restore high refresh rate
    hyprctl keyword monitor "$MONITOR,$RES@$HIGH_HZ,0x0,1"

    # 2. Re-enable Hyprland animations, shadows, and blur
    hyprctl --batch "\
        keyword animations:enabled 1;\
        keyword decoration:blur:enabled 1;\
        keyword decoration:drop_shadow 1;\
        keyword misc:vfr 1"

    # 3. Restore CPU governor to balanced/performance
    if command -v powerprofilesctl >/dev/null 2>&1; then
        powerprofilesctl set balanced
    fi

    # 4. Optional: Send desktop notification
    command -v notify-send >/dev/null 2>&1 && notify-send -u low "Power Mode" "Performance: RESTORED (144Hz, Effects On)"
fi
