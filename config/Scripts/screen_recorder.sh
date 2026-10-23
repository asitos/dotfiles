#!/usr/bin/env bash

set -euo pipefail

RECORD_DIR="$HOME/Pictures/Recordings"
TEMP_FILE="/tmp/wfr_last_file"
PID_FILE="/tmp/wfr.pid"
AUDIO_MODE_FILE="$HOME/.cache/screen_recorder_audio_mode"

mkdir -p "$RECORD_DIR"

get_audio_mode() {
    if [[ -f "$AUDIO_MODE_FILE" ]]; then
        cat "$AUDIO_MODE_FILE"
    else
        echo "system"
    fi
}

toggle_audio() {
    local current
    current=$(get_audio_mode)
    local next="system"

    case "$current" in
        system)
            next="mic"
            notify-send -u low "🎙️ Screen Recorder" "Audio: Microphone"
            ;;
        mic)
            next="none"
            notify-send -u low "🔇 Screen Recorder" "Audio: Muted (No Audio)"
            ;;
        *)
            next="system"
            notify-send -u low "🔊 Screen Recorder" "Audio: System Audio (Default)"
            ;;
    esac

    echo "$next" > "$AUDIO_MODE_FILE"
}

get_audio_dev() {
    local mode="$1"
    case "$mode" in
        system)
            local sink
            sink=$(pactl get-default-sink 2>/dev/null || true)
            if [[ -n "$sink" ]]; then
                echo "${sink}.monitor"
            fi
            ;;
        mic)
            pactl get-default-source 2>/dev/null || true
            ;;
        *)
            echo ""
            ;;
    esac
}

start_recording() {
    MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name')

    if [[ -z "$MONITOR" || "$MONITOR" == "null" ]]; then
        notify-send "❌ Recording failed" "Couldn't determine focused monitor."
        exit 1
    fi

    local mode
    mode=$(get_audio_mode)
    local audio_label=""
    local audio_dev=""

    case "$mode" in
        system)
            audio_label="🔊 System Audio"
            audio_dev=$(get_audio_dev "system")
            ;;
        mic)
            audio_label="🎙️ Microphone"
            audio_dev=$(get_audio_dev "mic")
            ;;
        none)
            audio_label="🔇 No Audio"
            audio_dev=""
            ;;
        *)
            audio_label="🔊 System Audio"
            audio_dev=$(get_audio_dev "system")
            ;;
    esac

    FILENAME="Screen_recording_$(date +"%d%m%Y_%H%M%S").mp4"
    OUTPUT="$RECORD_DIR/$FILENAME"

    notify-send "🔴 Recording Started" "Monitor: $MONITOR\nAudio: $audio_label"

    local -a cmd=(
        wf-recorder
        -r 60
        -c libx264
        -p crf=28
        -p preset=faster
        -x yuv420p
        -o "$MONITOR"
        -f "$OUTPUT"
    )

    if [[ "$mode" != "none" ]]; then
        if [[ -n "$audio_dev" ]]; then
            cmd+=(--audio="$audio_dev")
        else
            cmd+=(--audio)
        fi
    fi

    "${cmd[@]}" >/dev/null 2>&1 &

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

case "${1:-}" in
    --toggle-audio|-t|toggle)
        toggle_audio
        exit 0
        ;;
    --status)
        current_mode=$(get_audio_mode)
        notify-send -u low "Screen Recorder" "Audio mode: $current_mode"
        exit 0
        ;;
    --mic)
        echo "mic" > "$AUDIO_MODE_FILE"
        ;;
    --system)
        echo "system" > "$AUDIO_MODE_FILE"
        ;;
    --none)
        echo "none" > "$AUDIO_MODE_FILE"
        ;;
    "")
        ;;
    *)
        echo "Usage: $0 [--toggle-audio|--system|--mic|--none|--status]" >&2
        exit 1
        ;;
esac

if [[ -f "$PID_FILE" ]]; then
    stop_recording
else
    start_recording
fi
