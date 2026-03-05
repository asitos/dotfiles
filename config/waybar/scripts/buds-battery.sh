#!/bin/bash


LEFT=$(galaxybudsclient device -g BatteryLeft 2>/dev/null)
RIGHT=$(galaxybudsclient device -g BatteryRight 2>/dev/null)

if [[ -n "$LEFT" && -n "$RIGHT" ]]; then
  echo "{\"text\": \"L:${LEFT}% | R:${RIGHT}%\", \"tooltip\": \"rajma\nLeft: ${LEFT}%\nRight: ${RIGHT}%\"}"
else
  echo "{\"text\": \"\"}"
fi
