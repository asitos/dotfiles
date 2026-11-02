#!/usr/bin/env bash

if ! id -Gn | grep -qw "input"; then
    exec newgrp input << 'EOF'
exec bongocat --watch-config
EOF
fi
exec bongocat --watch-config
