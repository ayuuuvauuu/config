#!/bin/bash
set -euo pipefail

packages=(
    localsend
    cmus
    unp
    # WM / compositor
    sway swaylock swayidle swaybg
    
    # bar / launcher / notifications
    waybar rofi-wayland nwg-bar mako
    
    # terminal & shell
    foot fish tmux
    
    # editor / file manager / browser
    neovim thunar firefox
    
    # media
    mpv sioyek
    
    # audio / backlight
    pipewire wireplumber pamixer playerctl brightnessctl
    
    # screenshot / clipboard
    grim slurp swappy wl-clipboard cliphist
    
    # wallpaper / theming
    swww wallust imagemagick
    
    # shell tools
    eza bat fzf zoxide lazygit yazi fd ripgrep jq glow
    
    # system
    polkit-gnome network-manager-applet blueman
    xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk
    
    # AUR
    gpu-screen-recorder
    ytui-music
    mouseless
    orage
)

paru -S --needed --noconfirm "${packages[@]}"
