#!/usr/bin/env bash
set -uo pipefail

# Reports what is carrying traffic, not how to draw it: the shell owns the
# icons, and which codepoint means "three bars of signal" is not something a
# shell script should have an opinion about.
network_json() {
  local line device type state connection signal tooltip

  line="$(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION dev status 2>/dev/null | awk -F: '$3 == "connected" && $2 != "loopback" { print; exit }')"

  if [[ -z "$line" ]]; then
    jq -n '{type: "", signal: 0, tooltip: "Disconnected", connected: false}'
    return 0
  fi

  IFS=: read -r device type state connection <<< "$line"
  signal=0

  case "$type" in
    wifi)
      signal="$(nmcli -t -f IN-USE,SIGNAL dev wifi 2>/dev/null | awk -F: '$1 == "*" { print $2; exit }')"
      signal="${signal:-0}"
      tooltip="${connection:-$device} (${signal}%)"
      ;;
    *)
      tooltip="${device}: ${connection:-connected}"
      ;;
  esac

  jq -n --arg type "$type" --argjson signal "$signal" --arg tooltip "$tooltip" \
    '{type: $type, signal: $signal, tooltip: $tooltip, connected: true}'
}

jq -n \
  --argjson network "$(network_json)" \
  '{
    network: $network
  }'
