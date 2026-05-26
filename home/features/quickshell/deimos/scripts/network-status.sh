#!/usr/bin/env bash
set -euo pipefail

rescan="no"
if [[ "${1:-}" == "--rescan" ]]; then
  rescan="yes"
fi

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

json_bool() {
  if [[ "$1" == "true" ]]; then
    printf 'true'
  else
    printf 'false'
  fi
}

radio_state="$(nmcli -t -f WIFI g 2>/dev/null || true)"
wifi_enabled=false
if [[ "$radio_state" == "enabled" ]]; then
  wifi_enabled=true
fi

declare -A known_connections=()
while IFS=: read -r connection_name connection_type _; do
  [[ "$connection_type" == "802-11-wireless" ]] || continue

  ssid="$(nmcli -g 802-11-wireless.ssid connection show "$connection_name" 2>/dev/null || true)"
  ssid="${ssid:-$connection_name}"
  [[ -n "$ssid" ]] || continue

  known_connections["$ssid"]="$connection_name"
done < <(nmcli -e no -t -f NAME,TYPE connection show 2>/dev/null || true)

wired_json="$(
  nmcli -e no -t -f DEVICE,TYPE,STATE,CONNECTION dev status 2>/dev/null |
    while IFS=: read -r device type state connection _; do
      [[ "$type" == "ethernet" ]] || continue

      connected=false
      if [[ "$state" == connected* ]]; then
        connected=true
      fi

      jq -n \
        --arg device "$device" \
        --arg state "$state" \
        --arg connection "$connection" \
        --argjson connected "$(json_bool "$connected")" \
        '{device: $device, state: $state, connection: $connection, connected: $connected}'
    done |
    jq -s '.'
)"

declare -A wifi_signal=()
declare -A wifi_security=()
declare -A wifi_active=()

current_in_use=""
current_ssid=""
current_signal=""
current_security=""

record_wifi() {
  local ssid="$1"
  local signal="$2"
  local security="$3"
  local in_use="$4"

  [[ -n "$ssid" && "$ssid" != "--" ]] || return 0
  [[ "$signal" =~ ^[0-9]+$ ]] || signal=0
  [[ "$security" == "--" ]] && security=""

  if [[ -z "${wifi_signal[$ssid]+set}" || "$signal" -gt "${wifi_signal[$ssid]}" ]]; then
    wifi_signal["$ssid"]="$signal"
    wifi_security["$ssid"]="$security"
  fi

  if [[ "$in_use" == "*" ]]; then
    wifi_active["$ssid"]="true"
  elif [[ -z "${wifi_active[$ssid]+set}" ]]; then
    wifi_active["$ssid"]="false"
  fi
}

while IFS= read -r line; do
  key="$(trim "${line%%:*}")"
  value="$(trim "${line#*:}")"

  case "$key" in
    IN-USE)
      if [[ -n "$current_ssid" || -n "$current_signal" || -n "$current_security" ]]; then
        record_wifi "$current_ssid" "$current_signal" "$current_security" "$current_in_use"
      fi

      current_in_use="$value"
      current_ssid=""
      current_signal=""
      current_security=""
      ;;
    SSID)
      current_ssid="$value"
      ;;
    SIGNAL)
      current_signal="$value"
      ;;
    SECURITY)
      current_security="$value"
      ;;
  esac
done < <(nmcli -m multiline -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list --rescan "$rescan" 2>/dev/null || true)

if [[ -n "$current_ssid" || -n "$current_signal" || -n "$current_security" ]]; then
  record_wifi "$current_ssid" "$current_signal" "$current_security" "$current_in_use"
fi

wifi_json="$(
  for ssid in "${!wifi_signal[@]}"; do
    active="${wifi_active[$ssid]:-false}"
    known=false
    known_connection="${known_connections[$ssid]:-}"

    if [[ -n "$known_connection" ]]; then
      known=true
    fi

    jq -n \
      --arg ssid "$ssid" \
      --arg security "${wifi_security[$ssid]:-}" \
      --arg knownConnection "$known_connection" \
      --argjson signal "${wifi_signal[$ssid]}" \
      --argjson active "$(json_bool "$active")" \
      --argjson known "$(json_bool "$known")" \
      '{ssid: $ssid, signal: $signal, security: $security, active: $active, known: $known, knownConnection: $knownConnection}'
  done |
    jq -s 'sort_by([if .active then 0 else 1 end, -(.signal)])'
)"

active_wifi="$(jq -r '.[] | select(.active) | .ssid' <<< "$wifi_json" | head -n 1)"

jq -n \
  --argjson wifiEnabled "$(json_bool "$wifi_enabled")" \
  --arg activeWifi "$active_wifi" \
  --argjson wired "$wired_json" \
  --argjson wifi "$wifi_json" \
  '{wifiEnabled: $wifiEnabled, activeWifi: $activeWifi, wired: $wired, wifi: $wifi}'
