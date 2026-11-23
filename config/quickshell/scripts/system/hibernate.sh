#!/usr/bin/env bash

systemctl hibernate 2>/dev/null || loginctl hibernate 2>/dev/null
