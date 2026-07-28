#!/bin/bash

# Get current mode
CURRENT_MODE=$(powerprofilesctl get)

if [ "$CURRENT_MODE" == "power-saver" ]; then
    powerprofilesctl set balanced
    notify-send -u low " Balanced Mode"
elif [ "$CURRENT_MODE" == "balanced" ]; then
    powerprofilesctl set performance
    notify-send -u low " Performance Mode"
else
    powerprofilesctl set power-saver
    notify-send -u low " Power Saver"
fi

# Refresh Waybar Module Immediately
pkill -RTMIN+8 waybar
