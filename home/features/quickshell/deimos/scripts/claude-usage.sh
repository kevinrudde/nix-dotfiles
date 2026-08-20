#!/usr/bin/env bash
# Token usage from Claude Code's own session transcripts, plus the
# authoritative rate-limit percentages from Anthropic's OAuth usage
# endpoint — the same one Claude Code's own client and Omarchy's agents
# panel use. Read-only: this never refreshes or writes back the access
# token. Only the CLI itself can mint a new one, so an expired token here
# just means "start Claude Code, or run `claude auth login`" rather than
# an attempt to renew it ourselves.
set -uo pipefail

days="${1:-7}"
force=false
[[ "${2:-}" == "--force" ]] && force=true

claude_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
projects_dir="$claude_dir/projects"
creds_file="$claude_dir/.credentials.json"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell-claude-usage"
limits_cache="$cache_dir/limits.json"
usage_endpoint="https://api.anthropic.com/api/oauth/usage"
probe_min_interval=15
auth_help_default='Run `claude auth login` to restore authoritative usage.'

mkdir -p "$cache_dir" 2>/dev/null

emit_empty() {
  jq -n '{byDay: [], byModel: [], session: null, limits: [], tierLabel: "", usageStatusText: "", authHelpText: ""}'
}

command -v jq >/dev/null 2>&1 || { echo '{"byDay":[],"byModel":[],"session":null,"limits":[],"tierLabel":"","usageStatusText":"","authHelpText":""}'; exit 0; }

# ── Local usage: tokens by day, by model, current 5-hour block ────────────
usage_json='{"byDay":[],"byModel":[],"session":null}'

if [[ -d "$projects_dir" ]]; then
  # Transcripts older than the window can hold nothing relevant — skips
  # scanning months of history on every refresh.
  mapfile -t files < <(find "$projects_dir" -name "*.jsonl" -type f -mtime "-$((days + 1))" 2>/dev/null)

  if [[ ${#files[@]} -gt 0 ]]; then
    tmp=$(mktemp)
    cutoff_date="$(date -u -d "-$((days - 1)) days" +%Y-%m-%d)"

    # One file at a time and tolerant of a bad one: a single truncated or
    # mid-write transcript must not blank out every other project's usage.
    for file in "${files[@]}"; do
      jq -c --arg cutoff "$cutoff_date" '
        select(.type == "assistant" and .message.usage != null and (.timestamp // "") >= $cutoff) |
        {
          date: (.timestamp[0:10]),
          ts: .timestamp,
          model: (.message.model // "unknown"),
          tokens: ((.message.usage.input_tokens // 0) + (.message.usage.output_tokens // 0)
            + (.message.usage.cache_creation_input_tokens // 0) + (.message.usage.cache_read_input_tokens // 0))
        }
      ' "$file" 2>/dev/null >> "$tmp" || true
    done

    # All dates in the window, so a day with no messages still shows as zero
    # rather than silently disappearing from the day-by-day list.
    all_dates_json="$(
      for i in $(seq $((days - 1)) -1 0); do
        date -u -d "-$i days" +%Y-%m-%d
      done | jq -R . | jq -s .
    )"

    # Rate limit windows are anchored to first-message time, not to gaps — a
    # window stays open for exactly 5 hours from its own start regardless of
    # quiet periods in between, so the walk below only ever starts a new one
    # once that much wall-clock time has actually passed.
    usage_json="$(jq -s \
      --argjson allDates "$all_dates_json" \
      --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      '
      def toEpoch: sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601;

      (map(. + {epoch: (.ts | toEpoch)}) | sort_by(.epoch)) as $rows |
      ($now | toEpoch) as $nowEpoch |

      {
        byDay: ($allDates | map(. as $d | {
          date: $d,
          tokens: ([$rows[] | select(.date == $d) | .tokens] | add // 0)
        })),

        byModel: ($rows | group_by(.model) | map({
          model: .[0].model,
          tokens: (map(.tokens) | add)
        }) | map(select(.tokens > 0)) | sort_by(-.tokens)),

        session: (
          if ($rows | length) == 0 then null else
            (reduce $rows[] as $r (
              {blocks: [], start: null, end: null};
              if .start == null or ($r.epoch >= .end) then
                .blocks += [{start: $r.ts, startEpoch: $r.epoch, tokens: 0, messages: 0}]
                | .start = $r.epoch
                | .end = ($r.epoch + 18000)
              else . end
              | .blocks[-1].tokens += $r.tokens
              | .blocks[-1].messages += 1
            ).blocks | last) as $block |
            {
              tokens: $block.tokens,
              messages: $block.messages,
              startedAt: $block.start,
              resetsAt: (($block.startEpoch + 18000) | todateiso8601),
              active: (($block.startEpoch + 18000) > $nowEpoch)
            }
          end
        )
      }
      ' "$tmp")"
    rm -f "$tmp"
  fi
fi

# ── Plan label and access token, read directly — no CLI shellout ──────────
tier_label=""
access_token=""
expires_at_ms=0

if [[ -f "$creds_file" ]]; then
  access_token="$(jq -r '.claudeAiOauth.accessToken // ""' "$creds_file" 2>/dev/null)"
  expires_at_ms="$(jq -r '.claudeAiOauth.expiresAt // 0' "$creds_file" 2>/dev/null)"
  rate_limit_tier="$(jq -r '.claudeAiOauth.rateLimitTier // ""' "$creds_file" 2>/dev/null)"
  subscription_type="$(jq -r '.claudeAiOauth.subscriptionType // ""' "$creds_file" 2>/dev/null)"

  if [[ "$rate_limit_tier" =~ max_([0-9]+x) ]]; then
    tier_label="Max ${BASH_REMATCH[1]}"
  elif [[ -n "$subscription_type" ]]; then
    tier_label="$(tr '[:lower:]' '[:upper:]' <<<"${subscription_type:0:1}")${subscription_type:1}"
  fi
fi

# ── Rate limits from Anthropic's OAuth usage endpoint ──────────────────────
now_ms=$(($(date +%s) * 1000))
usage_status_text=""
auth_help_text="$auth_help_default"
limits_json="[]"

# A window whose reset time has already passed describes a period that is
# over — showing its last-known percentage would misreport an allowance
# that has since cleared. A window with no reset time, or one this cannot
# parse, is kept: an unreadable timestamp is no reason to throw away a real
# number.
usable_cached_limits() {
  [[ -f "$limits_cache" ]] || { echo "[]"; return; }
  local now_epoch entry_epoch resets_at
  now_epoch=$(date -u +%s)
  jq -c '.limits // []' "$limits_cache" 2>/dev/null | jq -c --argjson now "$now_epoch" '
    [.[] | select(
      (.resetsAt // "") == "" or
      (try ((.resetsAt | sub("(\\.[0-9]+)?(Z|[+-][0-9]{2}:[0-9]{2})$"; "Z") | fromdateiso8601) > $now) catch true)
    )]
  ' 2>/dev/null || echo "[]"
}

if [[ -z "$access_token" ]]; then
  limits_json="$(usable_cached_limits)"
  usage_status_text="Waiting for auth"
elif [[ "$expires_at_ms" -gt 0 && "$expires_at_ms" -le "$now_ms" ]]; then
  limits_json="$(usable_cached_limits)"
  usage_status_text="Sign-in expired"
  if [[ "$limits_json" != "[]" ]]; then
    auth_help_text="Claude Code's saved sign-in expired — showing the last known limits. Start Claude Code, or run \`claude auth login\`, to refresh it."
  else
    auth_help_text="Claude Code's saved sign-in expired. Start Claude Code, or run \`claude auth login\`, to refresh it."
  fi
else
  fetched_at_ms=0
  [[ -f "$limits_cache" ]] && fetched_at_ms="$(jq -r '.fetchedAtMs // 0' "$limits_cache" 2>/dev/null || echo 0)"
  fallback_limits="$(usable_cached_limits)"
  age_seconds=$(((now_ms - fetched_at_ms) / 1000))

  if [[ "$fallback_limits" != "[]" && "$force" == "false" && "$age_seconds" -lt "$probe_min_interval" ]]; then
    limits_json="$fallback_limits"
  else
    body_file="$(mktemp)"
    headers_file="$(mktemp)"
    http_code="$(curl -sS -m 10 -o "$body_file" -D "$headers_file" -w '%{http_code}' \
      -H "Authorization: Bearer $access_token" \
      -H "anthropic-beta: oauth-2025-04-20" \
      -H "Accept: application/json" \
      "$usage_endpoint" 2>/dev/null || echo "000")"

    if [[ "$http_code" == "000" ]]; then
      # A transport failure reached no server at all — no route, no DNS.
      # Any real answer, including an error status, is a server that
      # should stop being pestered; this is not one.
      limits_json="$fallback_limits"
      if [[ "$limits_json" == "[]" ]]; then
        usage_status_text="Claude limits unavailable"
        auth_help_text="Couldn't reach Anthropic's usage endpoint. Retrying shortly. Local Claude Code stats are still shown."
      fi
    elif [[ "$http_code" -ge 400 ]]; then
      limits_json="$fallback_limits"
      if [[ "$limits_json" == "[]" ]]; then
        usage_status_text="Claude limits unavailable"
        if [[ "$http_code" == "429" ]]; then
          retry_after="$(grep -i '^retry-after:' "$headers_file" 2>/dev/null | tr -d '\r' | awk '{print $2}')"
          if [[ -n "$retry_after" ]]; then
            auth_help_text="Anthropic's usage endpoint is rate limiting checks right now (retry after ${retry_after}s). Local Claude Code stats are still shown."
          else
            auth_help_text="Anthropic's usage endpoint is rate limiting checks right now. Local Claude Code stats are still shown."
          fi
        else
          auth_help_text="Anthropic's usage endpoint returned status $http_code. Local Claude Code stats are still shown."
        fi
      fi
    else
      parsed="$(jq -c '
        def scopedWindow(kind):
          (kind | ascii_downcase) as $k |
          if ($k | test("month")) then "Monthly"
          elif ($k | test("week|day")) then "Weekly"
          elif ($k | test("hour|session")) then "Session"
          else "" end;

        (.seven_day_oauth_apps // .seven_day) as $weekly |
        .five_hour as $session |

        # One payload speaks one convention (a plain percent like 36, or a
        # 0-1 fraction) — every value here is compared on the same scale
        # rather than assuming its own, the same way the real endpoint
        # mixes both across older and newer accounts.
        ([$session.utilization, $weekly.utilization]
          + [.limits[]? | select(.scope.model.display_name != null or .scope.model.id != null) | .percent]
        ) as $raw |
        (any($raw[]?; . != null and (. > 1))) as $percentScale |

        def normPercent(v):
          if v == null then null
          elif $percentScale or (v > 1) then ([v, 100] | min)
          else ([v * 100, 100] | min) end;

        [
          (if $session != null and $session.utilization != null then
            {label: "Session (5-hour)", percent: (normPercent($session.utilization) | round), resetsAt: ($session.resets_at // "")}
          else null end),
          (if $weekly != null and $weekly.utilization != null then
            {label: "Weekly (7-day)", percent: (normPercent($weekly.utilization) | round), resetsAt: ($weekly.resets_at // "")}
          else null end)
        ] + [
          .limits[]? | select(.scope.model.display_name != null or .scope.model.id != null) |
          ((.scope.model.display_name // .scope.model.id) + " " + scopedWindow(.kind)) as $title |
          {label: $title, percent: (normPercent(.percent) | round), resetsAt: (.resets_at // "")}
        ] | map(select(. != null and .percent != null))
      ' "$body_file" 2>/dev/null)"

      if [[ -z "$parsed" || "$parsed" == "[]" || "$parsed" == "null" ]]; then
        limits_json="$fallback_limits"
        if [[ "$limits_json" == "[]" ]]; then
          usage_status_text="Claude limits unavailable"
          auth_help_text="Anthropic's usage endpoint returned no limits. Local Claude Code stats are still shown."
        fi
      else
        limits_json="$parsed"
        jq -n --argjson limits "$limits_json" --argjson fetchedAtMs "$now_ms" '{fetchedAtMs: $fetchedAtMs, limits: $limits}' >"$limits_cache" 2>/dev/null || true
      fi
    fi
    rm -f "$body_file" "$headers_file"
  fi
fi

jq -n \
  --argjson usage "$usage_json" \
  --argjson limits "$limits_json" \
  --arg tierLabel "$tier_label" \
  --arg usageStatusText "$usage_status_text" \
  --arg authHelpText "$auth_help_text" \
  '$usage + {limits: $limits, tierLabel: $tierLabel, usageStatusText: $usageStatusText, authHelpText: $authHelpText}'
