#!/usr/bin/env bash

set -euo pipefail

RECORD_DIR="$HOME/Pictures/Recordings"
TEMP_FILE="/tmp/wfr_last_file"
PID_FILE="/tmp/wfr.pid"

mkdir -p "$RECORD_DIR"

start_recording() {
    MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name')

    if [[ -z "$MONITOR" || "$MONITOR" == "null" ]]; then
        notify-send "❌ Recording failed" "Couldn't determine focused monitor."
        exit 1
    fi

    FILENAME="Screen_recording_$(date +"%d%m%Y_%H%M%S").mp4"
    OUTPUT="$RECORD_DIR/$FILENAME"

    notify-send "🔴 Recording Started" "Monitor: $MONITOR"

    wf-recorder \
        --audio \
        -o "$MONITOR" \
        -f "$OUTPUT" >/dev/null 2>&1 &

    PID=$!

    sleep 1

    if ! kill -0 "$PID" 2>/dev/null; then
        notify-send "❌ Recording failed" "wf-recorder exited immediately."
        exit 1
    fi

    echo "$PID" > "$PID_FILE"
    echo "$FILENAME" > "$TEMP_FILE"
}

stop_recording() {
    if [[ ! -f "$PID_FILE" ]]; then
        notify-send "Recording" "No active recording."
        exit 0
    fi

    PID=$(cat "$PID_FILE")

    if kill -0 "$PID" 2>/dev/null; then
        kill -INT "$PID"

        while kill -0 "$PID" 2>/dev/null; do
            sleep 0.2
        done
    fi

    rm -f "$PID_FILE"

    FILENAME=$(cat "$TEMP_FILE" 2>/dev/null || true)
    rm -f "$TEMP_FILE"

    FILE="$RECORD_DIR/$FILENAME"

    if [[ -n "$FILENAME" && -f "$FILE" ]]; then
        notify-send "✅ Recording Saved" "$FILENAME\nLocation: $RECORD_DIR"
    else
        notify-send "⚠️ Recording Stopped" "Output file not found."
    fi
}

if [[ -f "$PID_FILE" ]]; then
    stop_recording
else
    start_recording
fi
