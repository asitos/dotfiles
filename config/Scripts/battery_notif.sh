#!/bin/bash

THRESHOLD=20
CHECK_INTERVAL=120

while true; do
  BAT_LEVEL=$(cat /sys/class/power_supply/BAT1/capacity)
  BAT_STATUS=$(cat /sys/class/power_supply/BAT1/status)

  if [ "$BAT_STATUS" = "Discharging" ] && [ "$BAT_LEVEL" -le "$THRESHOLD" ]; then

    notify-send -u critical -t 5000 "battery khatam laadle (${BAT_LEVEL}%)"

    sleep 300
  else 
    sleep $CHECK_INTERVAL
  fi
done
