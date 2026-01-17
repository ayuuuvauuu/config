#!/bin/bash
# --- Configuration ---
# You can usually find your battery name by running: ls /sys/class/power_supply/
BATTERY="BAT0"
POLL_INTERVAL=60 # Check battery status every 60 seconds.
NOTIFICATION_TIMEOUT=10000 # 7 seconds in milliseconds.

# --- Script Logic ---
# Path to the battery information in the /sys filesystem.
BATTERY_PATH="/sys/class/power_supply/${BATTERY}"

# Check if the battery exists.
if [ ! -d "$BATTERY_PATH" ]; then
  notify-send -u critical "Battery Script Error" "Battery '${BATTERY}' not found at '${BATTERY_PATH}'. Please check your configuration."
  exit 1
fi

# Initialize notification flags.
NOTIFIED_30=false
NOTIFIED_90=false

# Main loop to monitor the battery.
while true; do
  # Get the current battery percentage and status (Charging/Discharging).
  CURRENT_PERCENTAGE=$(cat "${BATTERY_PATH}/capacity")
  STATUS=$(cat "${BATTERY_PATH}/status")

  if [ "$STATUS" = "Discharging" ]; then
    # Notify when battery hits 30% while discharging.
    if [ "$CURRENT_PERCENTAGE" -le 30 ] && [ "$NOTIFIED_30" = false ]; then
      notify-send -t "$NOTIFICATION_TIMEOUT" -u critical "Battery Low" "Plug in the charger!"
      NOTIFIED_30=true
    fi
    # Reset the 90% notification flag when discharging.
    NOTIFIED_90=false
  elif [ "$STATUS" = "Charging" ]; then
    # Notify when battery hits 90% while charging.
    if [ "$CURRENT_PERCENTAGE" -ge 90 ] && [ "$NOTIFIED_90" = false ]; then
      notify-send -t "$NOTIFICATION_TIMEOUT" -u critical "Battery Full" "Remove the charger"
      NOTIFIED_90=true
    fi
    # Reset the 30% notification flag when charging.
    NOTIFIED_30=false
  fi

  # Wait for the defined interval before checking again.
  sleep "$POLL_INTERVAL"
done
