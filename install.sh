#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"

# Colors
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
BLUE="\033[1;34m"
RESET="\033[0m"

INSTALL_DEPS=false
CHECK_ONLY=false

usage() {
    cat <<EOF
Usage: ./install.sh [OPTIONS]

Options:
  -i, --install-deps    Automatically install missing dependencies via pacman / AUR helper
  -c, --check           Check dependencies and configuration health only (no changes)
  -h, --help            Show this help message
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--install-deps) INSTALL_DEPS=true; shift ;;
        -c|--check)        CHECK_ONLY=true; shift ;;
        -h|--help)         usage ;;
        *) echo -e "${RED}Unknown option: $1${RESET}"; usage ;;
    esac
done

# Dependency definitions: command:package_name:category
DEPENDENCIES=(
    "hyprland:hyprland:Core"
    "quickshell:quickshell:Core"
    "kitty:kitty:Core"
    "fish:fish:Core"
    "jq:jq:Core"
    "matugen:matugen-bin:Rice/Theming"
    "clipse:clipse-bin:Rice/Theming"
    "tofi:tofi:Rice/Theming"
    "yazi:yazi:Rice/Theming"
    "pipewire:pipewire:Audio"
    "wireplumber:wireplumber:Audio"
    "brightnessctl:brightnessctl:Display"
    "jalpari-core:jalpari-core:Jalpari Helper"
    "jalpari-audio:jalpari-audio:Jalpari Helper"
)

check_dependencies() {
    echo -e "${BLUE}==>${RESET} Checking system dependencies..."
    local missing=()
    local missing_pkgs=()

    for entry in "${DEPENDENCIES[@]}"; do
        IFS=":" read -r cmd pkg category <<< "$entry"
        if command -v "$cmd" >/dev/null 2>&1; then
            echo -e "  [${GREEN}✓${RESET}] $cmd ($category)"
        else
            echo -e "  [${RED}✗${RESET}] $cmd ($category - package: $pkg)"
            missing+=("$cmd")
            # Only add to package manager list if not a custom jalpari helper
            if [[ "$pkg" != jalpari-* ]]; then
                missing_pkgs+=("$pkg")
            fi
        fi
    done

    echo ""
    if [[ ${#missing[@]} -eq 0 ]]; then
        echo -e "${GREEN}==> All dependencies satisfied!${RESET}"
    else
        echo -e "${YELLOW}==> Missing dependencies (${#missing[@]}): ${missing[*]}${RESET}"

        # Check if running on Arch Linux
        if command -v pacman >/dev/null 2>&1 && [[ ${#missing_pkgs[@]} -gt 0 ]]; then
            local aur_helper=""
            if command -v yay >/dev/null 2>&1; then
                aur_helper="yay"
            elif command -v paru >/dev/null 2>&1; then
                aur_helper="paru"
            fi

            if [ "$INSTALL_DEPS" = false ] && [ -t 0 ] && [ "$CHECK_ONLY" = false ]; then
                read -rp "Would you like to install missing packages via ${aur_helper:-pacman}? [y/N] " resp
                if [[ "$resp" =~ ^[Yy]$ ]]; then
                    INSTALL_DEPS=true
                fi
            fi

            if [ "$INSTALL_DEPS" = true ]; then
                echo -e "${BLUE}==>${RESET} Installing missing packages..."
                if [ -n "$aur_helper" ]; then
                    "$aur_helper" -S --needed "${missing_pkgs[@]}"
                else
                    sudo pacman -S --needed "${missing_pkgs[@]}"
                fi
            else
                echo -e "${YELLOW}To install missing packages manually, run:${RESET}"
                if [ -n "$aur_helper" ]; then
                    echo "  $aur_helper -S --needed ${missing_pkgs[*]}"
                else
                    echo "  sudo pacman -S --needed ${missing_pkgs[*]}"
                fi
            fi
        fi

        # Notice for jalpari helpers
        for m in "${missing[@]}"; do
            if [[ "$m" == jalpari-* ]]; then
                echo -e "${YELLOW}Note:${RESET} $m can be downloaded from GitHub releases (asitos/$m)."
            fi
        done
    fi
    echo ""
}

install_symlinks() {
    echo -e "${BLUE}==>${RESET} Installing dotfiles to $CONFIG_DIR..."
    mkdir -p "$CONFIG_DIR" "$BIN_DIR"

    for item_path in "$DOTFILES_DIR"/config/*; do
        [ -e "$item_path" ] || continue
        local name target
        name="$(basename "$item_path")"
        target="$CONFIG_DIR/$name"

        # Idempotent: already pointing to the exact item
        if [ -L "$target" ] && [ "$(readlink -f "$target" 2>/dev/null)" = "$(readlink -f "$item_path" 2>/dev/null)" ]; then
            echo -e "  [${GREEN}ok${RESET}] $name (already linked)"
            continue
        fi

        # Remove dead/broken symlinks cleanly
        if [ -L "$target" ] && [ ! -e "$target" ]; then
            rm -f "$target"
        fi

        # Backup existing non-symlink file/directory
        if [ -e "$target" ]; then
            local backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
            echo -e "  [${YELLOW}backup${RESET}] $target -> $backup"
            mv "$target" "$backup"
        fi

        ln -snf "$item_path" "$target"
        echo -e "  [${GREEN}link${RESET}] $name -> $target"
    done

    # Ensure jalpari config alias
    if [ -L "$CONFIG_DIR/jalpari" ] && [ "$(readlink -f "$CONFIG_DIR/jalpari" 2>/dev/null)" = "$(readlink -f "$CONFIG_DIR/quickshell" 2>/dev/null)" ]; then
        echo -e "  [${GREEN}ok${RESET}] jalpari -> $CONFIG_DIR/quickshell (already linked)"
    else
        ln -snf "$CONFIG_DIR/quickshell" "$CONFIG_DIR/jalpari"
        echo -e "  [${GREEN}link${RESET}] jalpari -> $CONFIG_DIR/quickshell"
    fi

    # Link CLI binaries to ~/.local/bin
    if [ -d "$DOTFILES_DIR/config/quickshell/bin" ]; then
        for bin_path in "$DOTFILES_DIR/config/quickshell/bin"/*; do
            [ -f "$bin_path" ] || continue
            local bin_name target_bin
            bin_name="$(basename "$bin_path")"
            target_bin="$BIN_DIR/$bin_name"
            chmod +x "$bin_path"

            if [ -L "$target_bin" ] && [ "$(readlink -f "$target_bin" 2>/dev/null)" = "$(readlink -f "$bin_path" 2>/dev/null)" ]; then
                echo -e "  [${GREEN}ok${RESET}] $bin_name (already linked in $BIN_DIR)"
            else
                ln -snf "$bin_path" "$target_bin"
                echo -e "  [${GREEN}bin${RESET}] $bin_name -> $target_bin"
            fi
        done
    fi

    echo ""
    echo -e "${GREEN}==> Setup complete! Configs symlinked to $CONFIG_DIR.${RESET}"
    echo "    Note: Neovim config is maintained separately at:"
    echo "    https://github.com/asitos/neovim-dotfiles"
}

check_dependencies

if [ "$CHECK_ONLY" = true ]; then
    echo -e "${BLUE}Check-only mode requested. No changes made.${RESET}"
    exit 0
fi

install_symlinks
