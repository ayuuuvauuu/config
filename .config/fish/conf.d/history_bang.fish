bind \! _history_bang_binding

function _history_bang_binding --on-event fish_postexec
    set -g __fish_last_command $argv[1]
end

bind \! "commandline -r (echo (history search --max-count=1 --prefix='' 2>/dev/null) | head -1)"