#!/usr/bin/env bash
# Quickshell / Jalpari autostart entrypoint for Hyprland

DAEMON_BIN="$(command -v jalparid 2>/dev/null || true)"
if [ -z "$DAEMON_BIN" ] || [ ! -x "$DAEMON_BIN" ]; then
    for candidate in "$HOME/.local/bin/jalparid" "$HOME/.config/quickshell/bin/jalparid" "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../quickshell/bin/jalparid"; do
        if [ -x "$candidate" ]; then
            DAEMON_BIN="$candidate"
            break
        fi
    done
fi

if [ -z "$DAEMON_BIN" ] || [ ! -x "$DAEMON_BIN" ]; then
    echo "Error: jalparid not found in PATH or standard config directories" >&2
    exit 1
fi

exec "$DAEMON_BIN" start
