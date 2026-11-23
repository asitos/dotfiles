#!/usr/bin/env bash

rm -f /tmp/jalparid.lock /tmp/jalparid.pid 2>/dev/null

systemctl poweroff -i 2>/dev/null || loginctl poweroff 2>/dev/null || poweroff
