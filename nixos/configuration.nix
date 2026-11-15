# /etc/nixos/configuration.nix
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 3;

  # Latest Linux Kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.initrd.availableKernelModules = [
    "vmd"
    "nvme"
    "xhci_pci"
    "ahci"
    "usb_storage"
    "sd_mod"
  ];

  # Hostname & Networking
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # Time zone & Locale
  time.timeZone = "Asia/Kolkata";
  i18n.defaultLocale = "en_US.UTF-8";

  # Nix & Flakes Settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # Hyprland Desktop Session
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Serpantinum Quickshell Desktop Suite (Installed strictly into /nix/store)
  programs.serpantinum.enable = true;

  # Pipewire Sound Architecture
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # Polkit & Security
  security.polkit.enable = true;

  # User Account (shares /home with Arch Linux)
  users.users.asitos = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" ];
    shell = pkgs.fish;
    packages = with pkgs; [
      tree
    ];
  };

  users.groups.asitos.gid = 1000;
  programs.fish.enable = true;

  # Shared /home partition
  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/32e89994-632f-4c92-9161-a1f7a2ecf6b5";
    fsType = "ext4";
  };

  # System Packages: Core tools and utilities
  environment.systemPackages = with pkgs; [
    vim
    neovim
    wget
    curl
    git
    kitty
    starship
    zoxide
    brightnessctl
    playerctl
    libnotify
  ];

  # Fonts (Nerd Fonts for Serpantinum / Quickshell icons)
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    noto-fonts
    noto-fonts-color-emoji
  ];

  # Compatibility version
  system.stateVersion = "26.05";
}
