#!/usr/bin/env bash

# Toggle / trigger Quickshell quickactions
TARGET="${1:-}"
SHELL_QML="$(realpath "${QS_SHELL_QML:-$HOME/.config/quickshell/Shell.qml}" 2>/dev/null || echo "$HOME/.config/quickshell/Shell.qml")"

case "$TARGET" in
    close)
        quickshell -p "$SHELL_QML" ipc call main handleCommand close "" "" >/dev/null 2>&1 || true
        ;;
    prev|next)
        quickshell -p "$SHELL_QML" ipc call main handleCommand toggle quickactions "$TARGET" >/dev/null 2>&1 || true
        ;;
    "")
        quickshell -p "$SHELL_QML" ipc call main handleCommand toggle quickactions "" >/dev/null 2>&1 || true
        ;;
    *)
        quickshell -p "$SHELL_QML" ipc call main handleCommand toggle quickactions "$TARGET" >/dev/null 2>&1 || true
        ;;
esac
