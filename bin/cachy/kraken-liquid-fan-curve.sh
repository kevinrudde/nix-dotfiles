#!/usr/bin/env bash
set -euo pipefail

# NZXT Kraken X models do not expose fan control through liquidctl.
# This script uses liquidctl to read the coolant temperature, then drives
# a motherboard PWM header through /sys/class/hwmon.
#
# Run as root:
#   sudo ./kraken-liquid-fan-curve.sh
#
# Tune these values for your system before using it.

AIO_MATCH="${AIO_MATCH:-Kraken X}"
AIO_HWMON_NAME="${AIO_HWMON_NAME:-x53}"

MB_HWMON_NAME="${MB_HWMON_NAME:-}"
# On this system, pwm1 is the radiator / CPU_FAN header.
# pwm2 is the front fan header.
# pwm4 is the rear case fan header.
MB_PWM_CHANNEL="${MB_PWM_CHANNEL:-1}"
IT87_FORCE_ID="${IT87_FORCE_ID:-0x8689}"

POLL_SECONDS="${POLL_SECONDS:-5}"
DEBUG="${DEBUG:-1}"
RESTORE_ON_EXIT="${RESTORE_ON_EXIT:-0}"
APPLY_PUMP_CURVE="${APPLY_PUMP_CURVE:-1}"

PUMP_CURVE_POINTS=(
  "20:70"
  "36:70"
  "40:85"
  "43:100"
)

# Temperature:duty points in Celsius and percent.
# The script linearly interpolates between points.
CURVE_POINTS=(
  "30:0"
  "34:0"
  "36:20"
  "38:35"
  "40:60"
  "42:85"
  "45:100"
)

log() {
  if [[ "$DEBUG" == "1" ]]; then
    printf '%s\n' "$*" >&2
  fi
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

require_cmd() {
  local cmd
  for cmd in "$@"; do
    command -v "$cmd" >/dev/null 2>&1 || die "missing required command: $cmd"
  done
}

find_hwmon_dir() {
  local wanted_name=$1
  local dir

  for dir in /sys/class/hwmon/hwmon*; do
    [[ -r "$dir/name" ]] || continue
    if [[ "$(<"$dir/name")" == "$wanted_name" ]]; then
      realpath "$dir"
      return 0
    fi
  done

  return 1
}

find_mb_hwmon_dir() {
  local dir

  if [[ -n "$MB_HWMON_NAME" ]]; then
    find_hwmon_dir "$MB_HWMON_NAME"
    return $?
  fi

  for dir in /sys/class/hwmon/hwmon*; do
    [[ -r "$dir/name" ]] || continue
    case "$(<"$dir/name")" in
      it8622|it8689)
        realpath "$dir"
        return 0
        ;;
    esac
  done

  return 1
}

reload_it87_for_board() {
  command -v modprobe >/dev/null 2>&1 || return 1

  modprobe -r it87 >/dev/null 2>&1 || true
  modprobe it87 ignore_resource_conflict=1 mmio=1 force_id="$IT87_FORCE_ID"
}

ensure_mb_hwmon_dir() {
  local dir

  if dir=$(find_mb_hwmon_dir); then
    if [[ -w "$dir/pwm$MB_PWM_CHANNEL" && -w "$dir/pwm${MB_PWM_CHANNEL}_enable" ]]; then
      printf '%s\n' "$dir"
      return 0
    fi
  fi

  log "Reloading it87 with force_id=$IT87_FORCE_ID to expose pwm$MB_PWM_CHANNEL"
  reload_it87_for_board || return 1
  sleep 1

  if dir=$(find_mb_hwmon_dir); then
    if [[ -w "$dir/pwm$MB_PWM_CHANNEL" && -w "$dir/pwm${MB_PWM_CHANNEL}_enable" ]]; then
      printf '%s\n' "$dir"
      return 0
    fi
  fi

  return 1
}

curve_duty() {
  local temp=$1
  local joined

  joined=$(printf '%s ' "${CURVE_POINTS[@]}")

  awk -v temp="$temp" -v curve="$joined" '
    BEGIN {
      n = split(curve, pairs, " ")
      count = 0

      for (i = 1; i <= n; i++) {
        if (pairs[i] == "") {
          continue
        }

        split(pairs[i], point, ":")
        count++
        t[count] = point[1] + 0
        d[count] = point[2] + 0
      }

      if (count == 0) {
        exit 1
      }

      if (temp <= t[1]) {
        print d[1]
        exit 0
      }

      for (i = 2; i <= count; i++) {
        if (temp <= t[i]) {
          span = t[i] - t[i - 1]
          if (span <= 0) {
            print d[i]
            exit 0
          }

          frac = (temp - t[i - 1]) / span
          duty = d[i - 1] + frac * (d[i] - d[i - 1])
          print int(duty + 0.5)
          exit 0
        }
      }

      print d[count]
    }
  '
}

initialize_liquidctl() {
  if liquidctl --match "$AIO_MATCH" initialize >/dev/null 2>&1; then
    log "Initialized $AIO_MATCH with liquidctl"
  else
    log "liquidctl initialize failed; continuing"
  fi
}

apply_pump_curve() {
  local point temp duty
  local -a args=()

  [[ "$APPLY_PUMP_CURVE" == "1" ]] || return 0

  for point in "${PUMP_CURVE_POINTS[@]}"; do
    temp=${point%%:*}
    duty=${point##*:}
    args+=("$temp" "$duty")
  done

  if liquidctl --match "$AIO_MATCH" set pump speed "${args[@]}" >/dev/null 2>&1; then
    log "Applied pump curve: ${PUMP_CURVE_POINTS[*]}"
  else
    log "Failed to apply pump curve"
  fi
}

read_liquid_temp_from_liquidctl() {
  liquidctl --match "$AIO_MATCH" status --json 2>/dev/null | jq -er '
    .[0].status[]
    | select(.key == "Liquid temperature")
    | .value
  '
}

read_liquid_temp_from_hwmon() {
  local aio_dir raw

  aio_dir=$(find_hwmon_dir "$AIO_HWMON_NAME") || return 1
  [[ -r "$aio_dir/temp1_input" ]] || return 1

  raw=$(<"$aio_dir/temp1_input")
  awk -v raw="$raw" 'BEGIN { printf "%.1f\n", raw / 1000 }'
}

read_liquid_temp() {
  local temp

  if temp=$(read_liquid_temp_from_liquidctl); then
    printf '%s\n' "$temp"
    return 0
  fi

  if temp=$(read_liquid_temp_from_hwmon); then
    log "Falling back to hwmon temperature from $AIO_HWMON_NAME"
    printf '%s\n' "$temp"
    return 0
  fi

  return 1
}

set_fan_duty() {
  local duty=$1
  local pwm_value

  (( duty < 0 )) && duty=0
  (( duty > 100 )) && duty=100

  pwm_value=$(( duty * 255 / 100 ))

  printf '1\n' >"$PWM_ENABLE_PATH"
  printf '%s\n' "$pwm_value" >"$PWM_PATH"
}

cleanup() {
  [[ "$RESTORE_ON_EXIT" == "1" ]] || return 0
  [[ -n "${ORIGINAL_PWM_ENABLE:-}" ]] || return 0
  [[ -n "${ORIGINAL_PWM:-}" ]] || return 0

  printf '%s\n' "$ORIGINAL_PWM" >"$PWM_PATH"
  printf '%s\n' "$ORIGINAL_PWM_ENABLE" >"$PWM_ENABLE_PATH"
}

main() {
  local temp duty last_duty=""

  (( EUID == 0 )) || die "run this script as root so it can access liquidctl and write pwm values"

  require_cmd liquidctl jq awk realpath

  [[ -n "$MB_PWM_CHANNEL" ]] || die "set MB_PWM_CHANNEL to the motherboard PWM header that controls your radiator fans"

  PWM_HWMON_DIR=$(ensure_mb_hwmon_dir) || die "could not find a writable motherboard pwm$MB_PWM_CHANNEL on it8622/it8689"
  PWM_PATH="$PWM_HWMON_DIR/pwm$MB_PWM_CHANNEL"
  PWM_ENABLE_PATH="$PWM_HWMON_DIR/pwm${MB_PWM_CHANNEL}_enable"

  [[ -w "$PWM_PATH" ]] || die "cannot write $PWM_PATH"
  [[ -w "$PWM_ENABLE_PATH" ]] || die "cannot write $PWM_ENABLE_PATH"

  ORIGINAL_PWM=$(<"$PWM_PATH")
  ORIGINAL_PWM_ENABLE=$(<"$PWM_ENABLE_PATH")
  trap cleanup EXIT INT TERM

  initialize_liquidctl
  apply_pump_curve

  log "AIO match: $AIO_MATCH"
  log "AIO hwmon fallback: $AIO_HWMON_NAME"
  log "Motherboard hwmon: $MB_HWMON_NAME"
  log "PWM path: $PWM_PATH"
  log "Polling every ${POLL_SECONDS}s"

  while true; do
    if ! temp=$(read_liquid_temp); then
      log "Could not read liquid temperature; retrying in ${POLL_SECONDS}s"
      sleep "$POLL_SECONDS"
      continue
    fi

    duty=$(curve_duty "$temp") || die "failed to calculate duty from curve"

    if [[ "$duty" != "$last_duty" ]]; then
      set_fan_duty "$duty"
      log "$(date '+%F %T') liquid=${temp}C duty=${duty}%"
      last_duty=$duty
    fi

    sleep "$POLL_SECONDS"
  done
}

main "$@"
