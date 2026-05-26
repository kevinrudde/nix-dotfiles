#!/usr/bin/env bash
set -uo pipefail

rescan="no"
if [[ "${1:-}" == "--scan" ]]; then
  rescan="yes"
fi

json_bool() {
  if [[ "$1" == "yes" || "$1" == "true" ]]; then
    printf 'true'
  else
    printf 'false'
  fi
}

field_value() {
  local field="$1"
  local text="$2"

  awk -F': ' -v field="$field" '$1 ~ "^[[:space:]]*" field "$" { print $2; exit }' <<< "$text"
}

device_json() {
  local address="$1"
  local fallback_name="$2"
  local info name alias icon paired trusted connected blocked

  info="$(bluetoothctl info "$address" 2>/dev/null || true)"
  name="$(field_value "Name" "$info")"
  alias="$(field_value "Alias" "$info")"
  icon="$(field_value "Icon" "$info")"
  paired="$(field_value "Paired" "$info")"
  trusted="$(field_value "Trusted" "$info")"
  connected="$(field_value "Connected" "$info")"
  blocked="$(field_value "Blocked" "$info")"

  jq -n \
    --arg address "$address" \
    --arg name "${alias:-${name:-$fallback_name}}" \
    --arg icon "$icon" \
    --argjson paired "$(json_bool "$paired")" \
    --argjson trusted "$(json_bool "$trusted")" \
    --argjson connected "$(json_bool "$connected")" \
    --argjson blocked "$(json_bool "$blocked")" \
    '{address: $address, name: $name, icon: $icon, paired: $paired, trusted: $trusted, connected: $connected, blocked: $blocked}'
}

show="$(bluetoothctl show 2>/dev/null || true)"
powered="$(field_value "Powered" "$show")"
discovering="$(field_value "Discovering" "$show")"

if [[ -z "$show" ]]; then
  jq -n '{powered: false, discovering: false, devices: []}'
  exit 0
fi

if [[ "$rescan" == "yes" && "$powered" == "yes" ]]; then
  bluetoothctl --timeout 4 scan on >/dev/null 2>&1 || true
  bluetoothctl scan off >/dev/null 2>&1 || true
fi

devices_json="$(
  bluetoothctl devices 2>/dev/null |
    awk '$1 == "Device" { address = $2; sub("^Device " address " ", ""); print address "\t" $0 }' |
    head -n 16 |
    while IFS=$'\t' read -r address name; do
      [[ -n "$address" ]] || continue
      device_json "$address" "$name"
    done |
    jq -s 'unique_by(.address) | sort_by([if .connected then 0 else 1 end, if .paired then 0 else 1 end, .name])'
)"

jq -n \
  --argjson powered "$(json_bool "$powered")" \
  --argjson discovering "$(json_bool "$discovering")" \
  --argjson devices "$devices_json" \
  '{powered: $powered, discovering: $discovering, devices: $devices}'
