#!/bin/bash

MAC="41:42:84:84:84:84"

# Trick bluetoothctl by feeding it the command as a string
if echo "info $MAC" | bluetoothctl | grep -qi "Connected: yes"; then
    # If connected, feed it the disconnect command
    echo "disconnect $MAC" | bluetoothctl
else
    # If disconnected, feed it the connect command
    echo "connect $MAC" | bluetoothctl
fi
