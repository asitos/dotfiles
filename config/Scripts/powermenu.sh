#!/usr/bin/env bash

entries="Lock\nSuspend\nLogout\nReboot\nShutdown"
selected=$(echo -e "$entries" | tofi --prompt-text "Session: ")

case "$selected" in
    *Lock*)
        hyprlock
        ;;
    *Suspend*)
        systemctl suspend
        ;;
    *Logout*)
        hyprctl dispatch exit
        ;;
    *Reboot*)
        systemctl reboot
        ;;
    *Shutdown*)
        systemctl poweroff
        ;;
esac
