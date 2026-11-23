#!/usr/bin/env bash

rm -f /tmp/jalparid.lock /tmp/jalparid.pid 2>/dev/null

systemctl reboot 2>/dev/null || loginctl reboot 2>/dev/null || reboot
