{ config, pkgs, ... }:

let
  dotfilesDir = "${config.home.homeDirectory}/Projects/dotfiles";
  link = config.lib.file.mkOutOfStoreSymlink;
in
{
  home.username = "asitos";
  home.homeDirectory = "/home/asitos";

  # ==========================================
  # 1. USER PACKAGES (Rice & Desktop Utilities)
  # ==========================================
  home.packages = with pkgs; [
    # Terminal & CLI essentials
    kitty
    fish
    starship
    zoxide
    eza
    bat
    fzf
    ripgrep
    fd
    jq

    # Desktop & Wayland tools
    waybar
    tofi
    mako
    libnotify
    clipse
    wl-clipboard
    btop
    yazi

    # Hyprland ecosystem
    hyprpaper
    hypridle
    hyprlock
    hyprshade
    hyprpicker
    hyprshot

    # Media & Recording
    cava
    playerctl
    pavucontrol
    pulseaudio # provides 'pactl' used in volume/spotify scripts
    grim
    slurp
    swappy
    wf-recorder # used in screen_recorder.sh
    brightnessctl
    socat

    # Development & System
    neovim
  ];

  # ==========================================
  # 2. LIVE DECLARATIVE SYMLINKS
  # ==========================================
  # Uses out-of-store symlinks so edits in ~/.config/ immediately
  # modify ~/Projects/dotfiles/ without rebuilding Nix!
  xdg.configFile = {
    "hypr".source = link "${dotfilesDir}/config/hypr";
    "kitty".source = link "${dotfilesDir}/config/kitty";
    "waybar".source = link "${dotfilesDir}/config/waybar";
    "fish".source = link "${dotfilesDir}/config/fish";
    "mako".source = link "${dotfilesDir}/config/mako";
    "tofi".source = link "${dotfilesDir}/config/tofi";
    "yazi".source = link "${dotfilesDir}/config/yazi";
    "btop".source = link "${dotfilesDir}/config/btop";
    "clipse".source = link "${dotfilesDir}/config/clipse";
    "Scripts".source = link "${dotfilesDir}/config/Scripts";
    "bongocat".source = link "${dotfilesDir}/config/bongocat";
    "haj".source = link "${dotfilesDir}/config/haj";
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  home.stateVersion = "24.11";
}
