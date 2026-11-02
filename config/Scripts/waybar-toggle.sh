#!/usr/bin/env bash

if pgrep -x waybar >/dev/null 2>&1; then
    pkill -x waybar
    pkill -f bongocat
else
    waybar &
    ~/.config/Scripts/bongocat.sh &
fi
