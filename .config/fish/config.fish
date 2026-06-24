set -U fish_greeting ""
set -gx TERM xterm-256color
set -g fish_key_bindings fish_vi_key_bindings
# set fzf_fd_opts --no-ignore
set -gx fzf_fd_opts --hidden --no-ignore
# theme
set -gx theme_color_scheme terminal-dark

# hydro gruvbox colors
set -U hydro_color_pwd 83a598
set -U hydro_color_git b8bb26
set -U hydro_color_prompt fabd2f
set -U hydro_color_error fb4934
set -U hydro_color_duration a89984
set -U hydro_color_start fe8019
set -gx fish_prompt_pwd_dir_length 3
set -gx theme_display_user yes
set -gx LANG "en_US.UTF-8"
set -gx theme_hide_hostname no
set -gx GIT_EDITOR vim
set -gx theme_hostname always
set -gx EDITOR vim
# set -gx RUSTC_WRAPPER "/usr/bin/sccache" use only for old pc
set -gx TERMINAL foot
set -gx TERM foot
set -gx fish_cursor_insert block

set -l pc 0
test -f /tmp/powertop-once && test -s /tmp/powertop-once && set pc (string trim < /tmp/powertop-once)
if test "$pc" -lt 1
    powertop --auto-tune
    math "$pc + 1" >/tmp/powertop-once
end


# aliases
alias 1 'arttime --nolearn -a stars -t "You are Destained for Greatness." --ac 0 -g "7m;60m;loop4"'
#alias 2 'arttime --nolearn -a unix -g "60m;loop10"'
alias l "eza --icons=always --git"
alias la "eza -all --icons=always --git"
alias ff "sway --unsupported-gpu"
alias bat "bat -p"
alias opc "opencode"
alias cl "clear"
alias john "/usr/bin/john"
# alias pdf "MESA_GL_VERSION_OVERRIDE=2.1 MESA_GLSL_VERSION_OVERRIDE=330 sioyek"
alias pdf "sioyek"
alias ll "eza -l --icons=always --git"
alias gpu "__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia"
alias lla "ll -A"
alias nv "nvim"
alias c "clear"
alias g git
alias lz lazygit
alias t "tmux -u"
function n
	set tmp (mktemp -t "yazi-cwd.XXXXXX")
	yazi $argv --cwd-file="$tmp"
	if set cwd (cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
		cd -- "$cwd"
	end
	rm -f -- "$tmp"
end
set -gx PATH bin $PATH
set -gx PATH $HOME/.npm/bin $PATH
set -gx PATH /usr/local/go/bin $PATH
set -gx PATH /home/ayu/.local/share/nvim/mason/bin $PATH
set -gx PATH /home/ayu/Public/zulu21.46.19-ca-jdk21.0.9-linux_x64/bin $PATH
set -gx PATH /home/ayu/Public/gradle-9.5.1/bin $PATH
set -gx PATH $HOME/go/bin $PATH
set -gx PATH ~/.local/bin/ $PATH
set -gx ANDROID_HOME /opt/android-sdk  # Or your manual path
set -gx PATH $ANDROID_HOME/bin $PATH
set -gx PATH $ANDROID_HOME/platform-tools $PATH
set -Ux ANTHROPIC_BASE_URL "http://localhost:8080"
set -Ux ANTHROPIC_AUTH_TOKEN "test"
zoxide init fish --hook pwd | source

# opencode
fish_add_path /home/ayu/.opencode/bin

# opencode
fish_add_path /home/ayu/.opencode/bin

# pacman/paru snapshot reminder
function __snap_remind -a name
    echo
    echo "  ┌──────────────────────────────────────────┐"
    echo "  │         TAKE A SNAPSHOT FIRST!           │"
    echo "  └──────────────────────────────────────────┘"
    echo "  snapper -c root create -d \"before $name\" && limine-snapper-sync"
    echo
end

function pacman
    switch "$argv[1]"
        case -S -U -R -Syu -Syyu
            __snap_remind pacman
    end
    command sudo pacman $argv
end

function paru
    switch "$argv[1]"
        case -S -U -R -Syu -Syyu
            __snap_remind paru
    end
    command paru $argv
end

function sudo
    if test (count $argv) -ge 2
        switch "$argv[1]"
            case pacman
                switch "$argv[2]"
                    case -S -U -R -Syu -Syyu
                        __snap_remind pacman
                end
            case paru
                switch "$argv[2]"
                    case -S -U -R -Syu -Syyu
                        __snap_remind paru
                end
        end
    end
    command sudo $argv
end

# Autostart Sway on TTY login
if not set -q WAYLAND_DISPLAY; and not set -q DISPLAY; and string match -q '/dev/tty*' (tty)
    exec sway --unsupported-gpu
end
