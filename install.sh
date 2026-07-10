#!/bin/bash
set -euo pipefail

# ╔════════════════════════════════════════════════════════════════╗
# ║  Install script                                                   ║
# ║  To change what gets installed, just edit the two arrays below.   ║
# ║  - `core`     : always offered                                    ║
# ║  - `optional` : asked about at runtime                            ║
# ╚════════════════════════════════════════════════════════════════╝

# ── Core packages (always offered) ──────────────────────────────────
core=(
    # apps / utils
    localsend tumblerd wtype bat feh gammastep arttime 7zip
    tree-sitter-cli cmus git-delta unp

    # fonts
    noto-fonts noto-fonts-cjk noto-fonts-emoji

    # WM / compositor
    sway swaylock swayidle swaybg

    # bar / launcher / notifications
    waybar rofi-wayland nwg-bar mako

    # terminal & shell
    foot fish tmux

    # editor / file manager / browser
    neovim thunar firefox gvfs

    # media
    mpv sioyek

    # audio / backlight
    pipewire wireplumber pamixer playerctl brightnessctl

    # screenshot / clipboard
    grim slurp swappy wl-clipboard cliphist

    # wallpaper / theming
    swww wallust imagemagick

    # shell tools
    eza fzf zoxide lazygit yazi fd ripgrep jq glow

    # system
    polkit-gnome network-manager-applet blueman
    xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk

    # languages / dev
    nodejs npm python python-pip base-devel

    # gaming / overlays
    gamescope mangohud lutris

    # sched-ext (scxctl, scx_lavd)
    scx-scheds

    # audio / power / network
    pavucontrol tlp upower proxychains-ng

    # system utils
    openssh rsync stress android-tools

    # benchmarks
    glmark2 gputest

    # AUR
    gpu-screen-recorder ytui-music mouseless orage
)

# ── Optional packages (asked at runtime) ───────────────────────────
optional=(
    whisper-cpp-vulkan   # speech: whisper-cli
)

# ───────────────────────────────────────────────────────────────────
#  You normally don't need to edit below this line.
# ───────────────────────────────────────────────────────────────────

# Build the combined list. Numbering stays fixed so skip-by-number is stable.
all=("${core[@]}" "${optional[@]}")
opt_start=$(( ${#core[@]} + 1 ))
opt_end=${#all[@]}
total=${#all[@]}

cols=$(tput cols 2>/dev/null || echo 80)

# Print a list numbered and word-wrapped to fill the screen width.
print_numbered() {
    local -a items=("$@")
    local line="" entry i=1
    for pkg in "${items[@]}"; do
        printf -v entry ' %3d) %s' "$i" "$pkg"
        if [[ -n $line ]] && (( ${#line} + ${#entry} + 1 > cols )); then
            printf '%s\n' "$line"
            line=""
        fi
        [[ -n $line ]] && line+=" "
        line+="$entry"
        i=$((i + 1))
    done
    [[ -n $line ]] && printf '%s\n' "$line"
}

# Parse a skip string like "3 4-9 12- 7" into an associative index set.
declare -A SKIP=()
parse_skip() {
    SKIP=()
    local input=${1//,/ } tok a b n
    for tok in $input; do
        if [[ $tok == *-* ]]; then
            a=${tok%-*}; b=${tok#*-}
            [[ -z $a ]] && a=1
            [[ -z $b ]] && b=$total
            for ((n = a; n <= b; n++)); do
                (( n >= 1 && n <= total )) && SKIP[$n]=1
            done
        elif [[ -n $tok ]]; then
            (( tok >= 1 && tok <= total )) && SKIP[$tok]=1 || echo "  ! ignoring bad number: $tok"
        fi
    done
}

# ── 1. Show everything ──────────────────────────────────────────────
echo "All available packages (numbered):"
echo
print_numbered "${all[@]}"
echo
echo "Optional packages are #${opt_start}–#${opt_end}."

# ── 2. Ask about optional ───────────────────────────────────────────
read -r -p $'\nInstall optional packages? [y/N] ' ans
install_opt=0
[[ $ans == [yY] ]] && install_opt=1

# ── 3. Ask which to skip (by number / range) ───────────────────────
echo
print_numbered "${all[@]}"
echo
read -r -p "Skip packages? Enter numbers/ranges (e.g. '3 4-9'), or Enter for none: " skipinput
parse_skip "$skipinput"

# ── 4. Build the final list ─────────────────────────────────────────
final=()
for i in "${!all[@]}"; do
    n=$((i + 1))
    if (( n >= opt_start && n <= opt_end && ! install_opt )); then
        continue
    fi
    [[ -n ${SKIP[$n]:-} ]] && continue
    final+=("${all[$i]}")
done

# ── 5. Show final selection and confirm ─────────────────────────────
echo
echo "Will install ${#final[@]} package(s):"
echo
print_numbered "${final[@]}"
echo

if (( ${#final[@]} == 0 )); then
    echo "Nothing to install. Bye."
    exit 0
fi

read -r -p "Proceed with paru? [Y/n] " p
[[ $p == [nN] ]] && { echo "Aborted."; exit 0; }

paru -S --needed --noconfirm "${final[@]}"
