#!/usr/bin/env bash

set -euo pipefail

RECORD_DIR="$HOME/Pictures/Recordings"
TEMP_FILE="/tmp/wfr_last_file"
PID_FILE="/tmp/wfr.pid"
STATUS_FILE="/tmp/wfr_status.json"
START_EPOCH_FILE="/tmp/wfr_start_epoch"
AUDIO_MODE_FILE="$HOME/.cache/screen_recorder_audio_mode"

mkdir -p "$RECORD_DIR"

get_audio_mode() {
    if [[ -f "$AUDIO_MODE_FILE" ]]; then
        cat "$AUDIO_MODE_FILE"
    else
        echo "system"
    fi
}

send_recorder_event() {
    local title="$1"
    local body="${2:-}"
    local audio_mode
    audio_mode=$(get_audio_mode)
    local is_active=false
    local pid=""

    if [[ -f "$PID_FILE" ]]; then
        pid=$(cat "$PID_FILE" 2>/dev/null || echo "")
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            is_active=true
        fi
    fi

    local start_epoch=0
    if [[ -f "$START_EPOCH_FILE" ]]; then
        start_epoch=$(cat "$START_EPOCH_FILE" 2>/dev/null || echo 0)
    fi

    local clean_body
    clean_body=$(echo -n "$body" | tr '\n' ' ')

    cat <<EOF > "$STATUS_FILE"
{
  "active": $is_active,
  "pid": "${pid}",
  "audio": "${audio_mode}",
  "startEpoch": ${start_epoch:-0},
  "title": "${title//\"/\\\"}",
  "body": "${clean_body//\"/\\\"}",
  "time": $(date +%s)
}
EOF

    local shell_qml="$(realpath "$HOME/.config/quickshell/Shell.qml" 2>/dev/null || echo "$HOME/.config/quickshell/Shell.qml")"
    if [[ -f "$shell_qml" ]]; then
        quickshell -p "$shell_qml" ipc call recorder notify "$title" "$clean_body" "$audio_mode" >/dev/null 2>&1 || true
    fi
}

notify-send() {
    local args=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -u|-t|-i|-a|-c)
                shift 2
                ;;
            -*)
                shift
                ;;
            *)
                args+=("$1")
                shift
                ;;
        esac
    done
    local title="${args[0]:-}"
    local body="${args[1]:-}"
    send_recorder_event "$title" "$body"
}

toggle_audio() {
    local current
    current=$(get_audio_mode)
    local next="system"

    case "$current" in
        system)
            next="mic"
            ;;
        mic)
            next="none"
            ;;
        *)
            next="system"
            ;;
    esac

    echo "$next" > "$AUDIO_MODE_FILE"

    case "$next" in
        mic)
            notify-send -u low "🎙️ Screen Recorder" "Audio: Microphone"
            ;;
        none)
            notify-send -u low "🔇 Screen Recorder" "Audio: Muted (No Audio)"
            ;;
        *)
            notify-send -u low "🔊 Screen Recorder" "Audio: System Audio (Default)"
            ;;
    esac
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

    date +%s > "$START_EPOCH_FILE"
    notify-send "🔴 Recording Started" "Monitor: $MONITOR | Audio: $audio_label"

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
        rm -f "$START_EPOCH_FILE"
        notify-send "❌ Recording failed" "wf-recorder exited immediately."
        exit 1
    fi

    echo "$PID" > "$PID_FILE"
    echo "$FILENAME" > "$TEMP_FILE"
    send_recorder_event "🔴 Recording Started" "Monitor: $MONITOR | Audio: $audio_label"
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

    rm -f "$PID_FILE" "$START_EPOCH_FILE"

    FILENAME=$(cat "$TEMP_FILE" 2>/dev/null || true)
    rm -f "$TEMP_FILE"

    FILE="$RECORD_DIR/$FILENAME"

    if [[ -n "$FILENAME" && -f "$FILE" ]]; then
        notify-send "✅ Recording Saved" "$FILENAME"
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
