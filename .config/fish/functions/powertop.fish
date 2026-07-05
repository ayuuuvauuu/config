function powertop --wraps powertop
    command sudo sh -c 'powertop "$@" >/dev/null 2>&1 &' powertop $argv
end
