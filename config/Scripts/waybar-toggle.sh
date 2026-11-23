#!/usr/bin/env bash

# Toggle Waybar visibility
killall -SIGUSR1 waybar 2>/dev/null || true
