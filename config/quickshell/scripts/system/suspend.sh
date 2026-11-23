#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCK_SCRIPT="$(cd "$SCRIPT_DIR/.." && pwd)/lock.sh"

if [ -f "$LOCK_SCRIPT" ]; then
    bash "$LOCK_SCRIPT" &
    sleep 0.5
fi

systemctl suspend 2>/dev/null || loginctl suspend 2>/dev/null
