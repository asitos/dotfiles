#!/bin/bash

MODE=$(powerprofilesctl get)

# Define Icons/Text based on mode
if [ "$MODE" == "performance" ]; then
    TEXT=""
    TOOLTIP="Performance Mode"
    CLASS="performance"
elif [ "$MODE" == "balanced" ]; then
    TEXT=""
    TOOLTIP="Balanced Mode"
    CLASS="balanced"
else
    TEXT=""
    TOOLTIP="Power Saver"
    CLASS="power-saver"
fi

# Output JSON for Waybar
printf '{"text": "%s", "alt": "%s", "tooltip": "%s", "class": "%s"}\n' "$TEXT" "$MODE" "$TOOLTIP" "$CLASS"
