#!/usr/bin/env bash

set -euo pipefail

DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"

TIME=$(date +"%d-%m-%Y_%H-%M-%S")
FILE="$DIR/Screenshot_${TIME}.png"

if grim - | tee "$FILE" | wl-copy; then
    notify-send "screenshot captured" "saved to $(basename "$FILE")\ncopied to clipboard!"
else
    notify-send "screenshot failed" "could not capture screen."
    exit 1
fi
