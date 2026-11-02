#!/usr/bin/env bash

pkill -f "kitty --class cava-hud" 2>/dev/null || true

if pgrep -f "cava-overlay.py" >/dev/null 2>&1; then
    pkill -f "cava-overlay.py"
    exit 0
fi

nohup python3 "$HOME/.config/Scripts/cava-overlay.py" </dev/null >/dev/null 2>&1 &
