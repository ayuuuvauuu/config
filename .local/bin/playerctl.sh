#!/usr/bin/env bash

ACTION="${1:-}"

case "$ACTION" in
    next|previous|play-pause|play|pause|stop) ;;
    *) exit 1 ;;
esac

# Allowed music services
ALLOWED_URL='(open[.]spotify[.]com|music[.]youtube[.]com|soundcloud[.]com|bandcamp[.]com)'

# Check available MPRIS players
while IFS= read -r player; do
    [[ -z "$player" ]] && continue

    case "$player" in
        # Native music players
        spotify|spotify.*|cmus|cmus.*)
            playerctl --player="$player" "$ACTION" 2>/dev/null
            exit $?
            ;;

        # Supported browser players
        firefox|firefox.*|chrome|chrome.*|chromium|chromium.*)
            url=$(playerctl --player="$player" metadata xesam:url 2>/dev/null)

            if [[ "$url" =~ $ALLOWED_URL ]]; then
                playerctl --player="$player" "$ACTION" 2>/dev/null
                exit $?
            fi
            ;;
    esac

done < <(playerctl --list-all 2>/dev/null)

exit 0
