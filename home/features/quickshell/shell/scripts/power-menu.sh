#!/usr/bin/env bash
set -euo pipefail

if ! command -v fuzzel >/dev/null 2>&1; then
  echo "fuzzel is required for the Quickshell power menu" >&2
  exit 1
fi

choice="$(
  printf '%s\n' "Lock" "Suspend" "Logout" "Reboot" "Shutdown" |
    fuzzel --dmenu --prompt="Power: " --width=18 --lines=5
)"

confirm_destructive() {
  local action="$1"
  local answer

  answer="$(
    printf '%s\n' "No" "Yes" |
      fuzzel --dmenu --prompt="${action}? " --width=18 --lines=2
  )"

  [[ "$answer" == "Yes" ]]
}

case "$choice" in
  Lock)
    uwsm app -- hyprlock
    ;;
  Suspend)
    systemctl suspend
    ;;
  Logout)
    hyprctl dispatch exit
    ;;
  Reboot)
    confirm_destructive "Reboot" && systemctl reboot
    ;;
  Shutdown)
    confirm_destructive "Shutdown" && systemctl poweroff
    ;;
esac
