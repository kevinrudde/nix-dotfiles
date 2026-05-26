#!/usr/bin/env bash
set -euo pipefail

json_escape() {
  local value="$1"

  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"

  printf '%s' "$value"
}

emit() {
  local text="$1"
  local tooltip="$2"
  local class="$3"

  printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' \
    "$(json_escape "$text")" \
    "$(json_escape "$tooltip")" \
    "$(json_escape "$class")"
}

read_attr() {
  local path="$1"

  if [[ -r "$path" ]]; then
    tr -d '\n' < "$path"
  fi

  return 0
}

abs_int() {
  local value="$1"

  if [[ "$value" == -* ]]; then
    printf '%s\n' "${value#-}"
  else
    printf '%s\n' "$value"
  fi
}

format_tenths() {
  local tenths="$1"

  printf '%d.%d W\n' "$((tenths / 10))" "$((tenths % 10))"
}

power_supply_dir="/sys/class/power_supply"
selected_battery=""
fallback_battery=""

for battery in "$power_supply_dir"/*; do
  [[ -d "$battery" ]] || continue
  [[ "$(read_attr "$battery/type")" == "Battery" ]] || continue
  [[ "$(read_attr "$battery/present")" != "0" ]] || continue

  if [[ -z "$fallback_battery" ]]; then
    fallback_battery="$battery"
  fi

  if [[ "$(read_attr "$battery/scope")" == "System" ]]; then
    selected_battery="$battery"
    break
  fi
done

battery="${selected_battery:-$fallback_battery}"

if [[ -z "$battery" ]]; then
  emit "-- W" "No battery power sensor found" "missing"
  exit 0
fi

status="$(read_attr "$battery/status")"
capacity="$(read_attr "$battery/capacity")"
power_uw="$(read_attr "$battery/power_now")"

if [[ -n "$power_uw" ]]; then
  power_uw="$(abs_int "$power_uw")"
  tenths="$(((power_uw + 50000) / 100000))"
else
  current_ua="$(read_attr "$battery/current_now")"
  voltage_uv="$(read_attr "$battery/voltage_now")"

  if [[ -z "$current_ua" || -z "$voltage_uv" ]]; then
    emit "-- W" "No power_now or current_now/voltage_now sensor found for $(basename "$battery")" "missing"
    exit 0
  fi

  current_ua="$(abs_int "$current_ua")"
  voltage_uv="$(abs_int "$voltage_uv")"
  tenths="$(((current_ua * voltage_uv + 50000000000) / 100000000000))"
fi

text="$(format_tenths "$tenths")"
tooltip="Battery power: $text"

if [[ -n "$status" ]]; then
  tooltip="$tooltip ($status"

  if [[ -n "$capacity" ]]; then
    tooltip="$tooltip, ${capacity}%"
  fi

  tooltip="$tooltip)"
fi

emit "$text" "$tooltip" "$(printf '%s' "$status" | tr '[:upper:]' '[:lower:]')"
