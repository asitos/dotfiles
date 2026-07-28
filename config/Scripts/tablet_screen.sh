#!/bin/bash

# 1. Create Monitor
hyprctl output create headless

# 2. Wait a split second for Hyprland to register the new screen
# (This is the magic sauce that fixes the "wrong monitor" bug)
sleep 1

# 3. Start ADB Tunnel (USB Connection)
adb reverse tcp:5900 tcp:5900 &

# 4. Start VNC
wayvnc --output=HEADLESS-2 &

