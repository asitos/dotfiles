#!/usr/bin/env bash
# Toggle blue-light-filter with fallback to vibrance

if [ "$(hyprshade current)" = "blue-light-filter" ]; then
    hyprshade on vibrance
    notify-send -t 1500 "Night Light" "Off (Vibrance active)" -h string:x-canonical-private-synchronous:nightlight
else
    hyprshade on blue-light-filter
    notify-send -t 1500 "Night Light" "On (Blue light filter active)" -h string:x-canonical-private-synchronous:nightlight
fi
