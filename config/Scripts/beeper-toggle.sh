#!/usr/bin/env bash

# Toggle Beeper special workspace, launch if not running
if ! pgrep -x beepertexts >/dev/null 2>&1 && ! pgrep -x beeper >/dev/null 2>&1; then
    rm -f "$HOME/.config/BeeperTexts/Singleton"*
    beeper >/dev/null 2>&1 &
    sleep 0.5
fi
hyprctl eval 'hl.dispatch(hl.dsp.workspace.toggle_special("scratch"))' >/dev/null 2>&1
