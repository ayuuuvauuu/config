source /usr/share/cachyos-fish-config/cachyos-config.fish

if status is-login
    if test (tty) = "/dev/tty1"
        exec Hyprland
    end
end

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end
