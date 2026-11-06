#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

echo "==> Installing dotfiles to $CONFIG_DIR..."
mkdir -p "$CONFIG_DIR"

for item_path in "$DOTFILES_DIR"/config/*; do
    [ -e "$item_path" ] || continue
    name="$(basename "$item_path")"
    target="$CONFIG_DIR/$name"

    # Skip if already pointing to this dotfiles repo
    if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$item_path")" ]; then
        echo "  [ok] $name (already linked)"
        continue
    fi

    # Backup existing configuration if present
    if [ -e "$target" ] || [ -L "$target" ]; then
        backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
        echo "  [backup] $target -> $backup"
        mv "$target" "$backup"
    fi

    ln -snf "$item_path" "$target"
    echo "  [link] $name -> $target"
done

echo ""
echo "==> Setup complete! Configs symlinked to $CONFIG_DIR."
echo "    Note: Neovim config is maintained separately at:"
echo "    https://github.com/asitos/neovim-dotfiles"
