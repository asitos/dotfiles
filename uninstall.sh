#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

echo "==> Uninstalling dotfiles from $CONFIG_DIR..."

for item_path in "$DOTFILES_DIR"/config/*; do
    [ -e "$item_path" ] || continue
    name="$(basename "$item_path")"
    target="$CONFIG_DIR/$name"

    # Only remove symlinks pointing to this repository
    if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$item_path")" ]; then
        rm "$target"

        # Look for the most recent backup
        latest_backup=""
        for bak in "$CONFIG_DIR"/"$name".bak*; do
            [ -e "$bak" ] || continue
            latest_backup="$bak"
        done

        if [ -n "$latest_backup" ]; then
            mv "$latest_backup" "$target"
            echo "  [restored] $name <- $(basename "$latest_backup")"
        else
            echo "  [removed]  $name (no backup found)"
        fi
    fi
done

echo ""
echo "==> Uninstall complete! Original configurations restored."
