#!/usr/bin/env bash
set -uo pipefail

read_attr() {
  local path="$1"

  if [[ -r "$path" ]]; then
    tr -d '\n' < "$path"
  fi

  return 0
}

selected_battery() {
  local power_supply_dir="/sys/class/power_supply"
  local selected=""
  local fallback=""
  local battery

  for battery in "$power_supply_dir"/*; do
    [[ -d "$battery" ]] || continue
    [[ "$(read_attr "$battery/type")" == "Battery" ]] || continue
    [[ "$(read_attr "$battery/present")" != "0" ]] || continue

    if [[ -z "$fallback" ]]; then
      fallback="$battery"
    fi

    if [[ "$(read_attr "$battery/scope")" == "System" ]]; then
      selected="$battery"
      break
    fi
  done

  printf '%s\n' "${selected:-$fallback}"
}

volume_json() {
  local target="$1"
  local line volume muted percent

  line="$(wpctl get-volume "$target" 2>/dev/null || true)"
  volume="$(printf '%s\n' "$line" | sed -n 's/^Volume: \([0-9.]\+\).*/\1/p')"
  muted=false

  if [[ "$line" == *"[MUTED]"* ]]; then
    muted=true
  fi

  if [[ -n "$volume" ]]; then
    percent="$(awk -v volume="$volume" 'BEGIN { printf "%d", (volume * 100) + 0.5 }')"
  else
    percent="0"
  fi

  jq -n --argjson muted "$muted" --argjson percent "$percent" '{muted: $muted, percent: $percent}'
}

audio_icon() {
  local muted="$1"
  local percent="$2"

  if [[ "$muted" == "true" ]]; then
    printf '%s\n' ""
  elif ((percent < 30)); then
    printf '%s\n' ""
  elif ((percent < 70)); then
    printf '%s\n' ""
  else
    printf '%s\n' ""
  fi
}

backlight_percent() {
  brightnessctl -m 2>/dev/null | awk -F, '{ gsub(/%/, "", $4); print $4; found = 1; exit } END { if (!found) print "0" }'
}

network_json() {
  local line device type state connection signal text tooltip connected

  line="$(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION dev status 2>/dev/null | awk -F: '$3 == "connected" && $2 != "loopback" { print; exit }')"

  if [[ -z "$line" ]]; then
    jq -n '{text: "", tooltip: "Disconnected", connected: false}'
    return 0
  fi

  IFS=: read -r device type state connection <<< "$line"
  connected=true

  case "$type" in
    wifi)
      signal="$(nmcli -t -f IN-USE,SIGNAL dev wifi 2>/dev/null | awk -F: '$1 == "*" { print $2; exit }')"
      text="${signal:-0}% "
      tooltip="${connection:-$device} (${signal:-0}%)"
      ;;
    ethernet)
      text="󰈀"
      tooltip="${device}: ${connection:-connected}"
      ;;
    *)
      text=""
      tooltip="${device}: ${connection:-connected}"
      ;;
  esac

  jq -n --arg text "$text" --arg tooltip "$tooltip" --argjson connected "$connected" \
    '{text: $text, tooltip: $tooltip, connected: $connected}'
}

bluetooth_json() {
  local show powered connected_devices count text tooltip connected

  show="$(bluetoothctl show 2>/dev/null || true)"
  powered="$(awk -F': ' '/^[[:space:]]*Powered:/ { print $2; exit }' <<< "$show")"

  if [[ -z "$show" || "$powered" != "yes" ]]; then
    jq -n '{text: "󰂲", tooltip: "Bluetooth off", powered: false, connected: false, count: 0}'
    return 0
  fi

  connected_devices="$(bluetoothctl devices Connected 2>/dev/null || true)"
  count="$(grep -c '^Device ' <<< "$connected_devices" || true)"
  connected=false
  text=""
  tooltip="Bluetooth on"

  if ((count > 0)); then
    connected=true
    text="${count} "
    tooltip="$(awk '$1 == "Device" { address = $2; sub("^Device " address " ", ""); print }' <<< "$connected_devices" | paste -sd ', ' -)"
  fi

  jq -n --arg text "$text" --arg tooltip "$tooltip" --argjson powered true --argjson connected "$connected" --argjson count "$count" \
    '{text: $text, tooltip: $tooltip, powered: $powered, connected: $connected, count: $count}'
}

battery_json() {
  local battery="$1"
  local capacity status icon text class

  if [[ -z "$battery" ]]; then
    jq -n '{text: "--% ", tooltip: "No battery found", class: "missing"}'
    return 0
  fi

  capacity="$(read_attr "$battery/capacity")"
  status="$(read_attr "$battery/status")"
  capacity="${capacity:-0}"

  if [[ "$status" == "Charging" ]]; then
    icon=""
  elif ((capacity >= 80)); then
    icon=""
  elif ((capacity >= 60)); then
    icon=""
  elif ((capacity >= 40)); then
    icon=""
  elif ((capacity >= 20)); then
    icon=""
  else
    icon=""
  fi

  text="${capacity}% ${icon}"
  class="good"

  if ((capacity <= 15)); then
    class="critical"
  elif ((capacity <= 30)); then
    class="warning"
  fi

  jq -n --arg text "$text" --arg tooltip "${status:-Battery}: ${capacity}%" --arg class "$class" \
    '{text: $text, tooltip: $tooltip, class: $class}'
}

sink_json="$(volume_json "@DEFAULT_AUDIO_SINK@")"
source_json="$(volume_json "@DEFAULT_AUDIO_SOURCE@")"
sink_muted="$(jq -r '.muted' <<< "$sink_json")"
sink_percent="$(jq -r '.percent' <<< "$sink_json")"
source_muted="$(jq -r '.muted' <<< "$source_json")"
sink_icon="$(audio_icon "$sink_muted" "$sink_percent")"
audio_text="${sink_percent}% ${sink_icon}"
if [[ "$sink_muted" == "true" ]]; then
  audio_text="muted ${sink_icon}"
fi

battery="$(selected_battery)"

jq -n \
  --argjson backlight "$(backlight_percent)" \
  --argjson sink "$sink_json" \
  --argjson source "$source_json" \
  --arg audioText "$audio_text" \
  --argjson sourceMuted "$source_muted" \
  --argjson network "$(network_json)" \
  --argjson bluetooth "$(bluetooth_json)" \
  --argjson battery "$(battery_json "$battery")" \
  --arg clock "$(date '+%a %d %b  %H:%M')" \
  '{
    backlight: $backlight,
    audio: {
      text: $audioText,
      sink: $sink,
      source: $source,
      sourceMuted: $sourceMuted
    },
    network: $network,
    bluetooth: $bluetooth,
    battery: $battery,
    clock: $clock
  }'
