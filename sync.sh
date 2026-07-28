#!/usr/bin/env bash

# Paths
DOTFILES_DIR="$HOME/Projects/dotfiles/config"
CONFIG_DIR="$HOME/.config"

TRACKED_CONFIGS=(
    "btop"
    "qBittorrent"
    "kitty"
    "waybar"
    "mako"
    "clipse"
    "hypr"
    "fish"
    "haj"
    "tofi"
    "nvim"
    "Scripts"
    "yazi"
)

case "$1" in
    pull|save)
        echo " Syncing: ~/.config -> ~/Projects/dotfiles/config/"
        mkdir -p "$DOTFILES_DIR"
        for item in "${TRACKED_CONFIGS[@]}"; do
            if [ -e "$CONFIG_DIR/$item" ]; then
                rsync -av --delete "$CONFIG_DIR/$item" "$DOTFILES_DIR/"
            else
                echo " Warning: $CONFIG_DIR/$item does not exist."
            fi
        done
        echo "✓ Local repo updated! Run 'git status' in ~/Projects/dotfiles to inspect."
        ;;

    push|apply)
        echo " Syncing: ~/Projects/dotfiles/config/ -> ~/.config/"
        for item in "${TRACKED_CONFIGS[@]}"; do
            if [ -e "$DOTFILES_DIR/$item" ]; then
                mkdir -p "$CONFIG_DIR"
                rsync -av "$DOTFILES_DIR/$item" "$CONFIG_DIR/"
            else
                echo " Warning: $DOTFILES_DIR/$item does not exist in repo."
            fi
        done
        echo "✓ System configs updated!"
        ;;

    *)
        echo "Usage: $0 {pull|push}"
        echo "  pull (or save)  : Copy from ~/.config to repository"
        echo "  push (or apply) : Copy from repository to ~/.config"
        exit 1
        ;;
esac
