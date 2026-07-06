function fish_mode_prompt; end

function _tide_enter_transient
    if not commandline --paging-mode
        and test -n "$(commandline)"
        set -g _tide_transient
        commandline -f repaint execute
    else
        commandline -f execute
    end
end

bind \r _tide_enter_transient
bind \n _tide_enter_transient
bind -M insert \r _tide_enter_transient
bind -M insert \n _tide_enter_transient
