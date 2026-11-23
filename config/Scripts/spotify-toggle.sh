#!/usr/bin/env bash

# Toggle Spotify special workspace, launch if not running
if ! pgrep -x spotify >/dev/null 2>&1; then
    rm -f "$HOME/.cache/spotify/Singleton"*
    spotify >/dev/null 2>&1 &
    sleep 0.5
fi
hyprctl eval 'hl.dispatch(hl.dsp.workspace.toggle_special("spotify"))' >/dev/null 2>&1
