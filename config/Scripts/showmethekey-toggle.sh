#!/usr/bin/env bash

set -euo pipefail

if killall -0 showmethekey-gtk 2>/dev/null; then
    killall -q showmethekey-gtk showmethekey-cli || true
    notify-send -u low -t 1500 "⌨️ ShowMeTheKey" "Keys overlay hidden"
else
    showmethekey-gtk -A -C >/dev/null 2>&1 &
    disown
    notify-send -u low -t 1500 "⌨️ ShowMeTheKey" "Keys overlay active"
fi
