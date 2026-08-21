#!/usr/bin/env bash
# Live telemetry for the currently active Wi-Fi connection: device, IP,
# gateway, band, one-shot ping/loss, and the connection's DNS configuration.
# Static per-network facts (signal, security, known/saved) already live in
# network-status.sh's output — this script only covers what that one poll
# cannot: things that change while the popup is open.
set -uo pipefail

device="$(nmcli -t -f DEVICE,TYPE,STATE dev status 2>/dev/null | awk -F: '$2 == "wifi" && $3 == "connected" { print $1; exit }')"

if [[ -z "$device" ]]; then
  jq -n '{connected: false}'
  exit 0
fi

connection="$(nmcli -g GENERAL.CONNECTION device show "$device" 2>/dev/null)"
ip_addr="$(nmcli -g IP4.ADDRESS device show "$device" 2>/dev/null | head -n1 | cut -d/ -f1)"
gateway="$(nmcli -g IP4.GATEWAY device show "$device" 2>/dev/null)"
dns="$(nmcli -g ipv4.dns connection show "$connection" 2>/dev/null)"
ignore_auto_dns="$(nmcli -g ipv4.ignore-auto-dns connection show "$connection" 2>/dev/null)"
# The connection profile's own `ipv4.dns` is empty on plain DHCP — it only
# ever holds a value once DNS has been overridden. `IP4.DNS` off the device
# is what actually got handed to the resolver either way, static or DHCP,
# so that is the one worth pinging.
# nmcli joins multiple values for one field with " | ", not a newline or
# comma — `head -n1` alone would hand ping the literal multi-value string.
effective_dns="$(nmcli -g IP4.DNS device show "$device" 2>/dev/null | awk -F' \\| ' '{print $1}')"

# `iw` reports frequency in MHz, not a band name — NetworkManager does not
# expose the band it actually picked, only the one a connection may request.
band=""
freq="$(iw dev "$device" link 2>/dev/null | awk '/freq:/ { print $2; exit }')"
if [[ -n "$freq" ]]; then
  freq_int="${freq%.*}"
  if [[ "$freq_int" =~ ^[0-9]+$ ]]; then
    if ((freq_int < 2500)); then
      band="2.4GHz"
    elif ((freq_int < 5900)); then
      band="5GHz"
    else
      band="6GHz"
    fi
  fi
fi

# A single probe, not an average: this runs every few seconds while the
# popup is open, and the header wants a live reading, not a historical one.
# The DNS server is one hop further than the gateway and answering it means
# the connection actually resolves names, not just that the AP is up — a
# closer stand-in for "is this connection usable" than a gateway-only ping.
# Falls back to the gateway when there is no known resolver to probe.
ping_target="${effective_dns:-$gateway}"
rtt=""
loss=""
if [[ -n "$ping_target" ]]; then
  ping_output="$(ping -c 1 -W 1 "$ping_target" 2>/dev/null)"
  rtt="$(printf '%s\n' "$ping_output" | sed -nE 's/.*time=([0-9.]+).*/\1/p')"
  loss="$(printf '%s\n' "$ping_output" | sed -nE 's/.*, ([0-9.]+)% packet loss.*/\1/p')"
fi

jq -n \
  --arg device "$device" \
  --arg connection "${connection:-}" \
  --arg ip "${ip_addr:-}" \
  --arg gateway "${gateway:-}" \
  --arg band "$band" \
  --arg pingMs "$rtt" \
  --arg packetLoss "$loss" \
  --arg pingTarget "${ping_target:-}" \
  --arg dns "${dns:-}" \
  --arg ignoreAutoDns "${ignore_auto_dns:-no}" \
  '{
    connected: true,
    device: $device,
    connection: $connection,
    ip: $ip,
    gateway: $gateway,
    band: $band,
    pingMs: (if $pingMs == "" then null else ($pingMs | tonumber) end),
    packetLoss: (if $packetLoss == "" then null else ($packetLoss | tonumber) end),
    pingTarget: $pingTarget,
    dns: $dns,
    ignoreAutoDns: ($ignoreAutoDns == "yes")
  }'
