#!/usr/bin/env bash
# Pull requests that need a decision from you: reviews requested from you
# directly, reviews requested from a team you belong to, and pull requests
# assigned to you. Authentication is delegated entirely to the gh CLI
# credential store — no token handling here.
set -uo pipefail

emit_state() {
  jq -n --arg state "$1" --arg message "$2" \
    '{state:$state,message:$message,fetchedAt:(now|todateiso8601),reviewRequests:[],teamReviewRequests:[],assignedPullRequests:[],warnings:[]}'
}

command -v jq >/dev/null 2>&1 || { printf '%s\n' '{"state":"error","message":"jq is required.","reviewRequests":[],"teamReviewRequests":[],"assignedPullRequests":[],"warnings":[]}'; exit 0; }
command -v gh >/dev/null 2>&1 || { emit_state "gh-not-installed" "GitHub CLI is not installed or not on PATH."; exit 0; }
gh auth status -h github.com >/dev/null 2>&1 || { emit_state "logged-out" "Sign in with gh auth login to load GitHub data."; exit 0; }

error_detail() {
  tr '\n' ' ' <"$1" |
    sed -E 's/(gh[pousr]_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,})/[REDACTED]/g; s/(Authorization: *(token|Bearer) +)[^ ]+/\1[REDACTED]/Ig; s/[[:space:]]+/ /g; s/^ //; s/ $//' |
    cut -c1-200
}

tmp=$(mktemp -d) || { emit_state "error" "Could not prepare temporary storage."; exit 1; }
trap 'rm -rf "$tmp"' EXIT
warnings="$tmp/warnings"
: >"$warnings"

# GraphQL rather than the REST search endpoint: only GraphQL's search carries
# the head commit's check rollup alongside the pull request itself, and the
# per-PR check state is exactly what the panel colours its icons by. Search
# syntax is otherwise identical between the two endpoints.
pr_search_query='query($search:String!) { search(query:$search,type:ISSUE,first:50) { nodes { ... on PullRequest {
  number title url updatedAt createdAt isDraft repository { nameWithOwner }
  commits(last:1) { nodes { commit { statusCheckRollup { state } } } }
} } } }'

fetch_pr_search() {
  local label=$1 query=$2 output=$3
  local err="$tmp/$label.err" result

  if result=$(gh api graphql -f query="$pr_search_query" -F search="$query" 2>"$err"); then
    printf '%s\n' "$result" | jq '[.data.search.nodes[] | select(.number != null) | {
        id: ((.repository.nameWithOwner // "") + "#" + (.number|tostring)),
        number,
        title: (.title // ""),
        repository: (.repository.nameWithOwner // ""),
        url: (.url // ""),
        updatedAt: (.updatedAt // ""),
        createdAt: (.createdAt // ""),
        draft: (.isDraft // false),
        # A pull request with no configured workflows reports a null rollup,
        # which is a distinct state from pending and must not render as one.
        checks: (.commits.nodes[0].commit.statusCheckRollup.state // "NONE")
      }] | sort_by(.updatedAt) | reverse' >"$output" 2>/dev/null ||
      { printf '[]\n' >"$output"; printf '%s: invalid API response\n' "$label" >>"$warnings"; }
  else
    printf '[]\n' >"$output"
    printf '%s: %s\n' "$label" "$(error_detail "$err")" >>"$warnings"
  fi
}

# Archived repositories are read-only: a review request or assignment there
# cannot be acted on, so it would otherwise sit in the list forever. Drafts
# are excluded from review requests — nothing to review yet — but not from
# assignments, since being assigned a draft is still real, expected work.
# `user-review-requested` rather than `review-requested`: the latter also
# matches a request routed to a team the user belongs to, which is not a
# request of the user specifically and floods the list on any team-owned repo.
fetch_pr_search review-requests "is:open is:pr user-review-requested:@me draft:false archived:false" "$tmp/reviews.json"
fetch_pr_search assigned-prs "is:open is:pr assignee:@me archived:false" "$tmp/assigned.json"

# GitHub's search has no qualifier for "requested from a team, not from me
# directly" — `team-review-requested:@me` is accepted but silently matches
# nothing. So the superset is fetched and the direct list subtracted from it
# locally; `id` (repository#number) is already the row's unique key.
fetch_pr_search all-review-requests "is:open is:pr review-requested:@me draft:false archived:false" "$tmp/all-reviews.json"
jq -s '(.[0] | map(.id)) as $direct | [.[1][] | select(.id as $id | ($direct | index($id)) == null)]' \
  "$tmp/reviews.json" "$tmp/all-reviews.json" >"$tmp/team-reviews.json" 2>/dev/null ||
  printf '[]\n' >"$tmp/team-reviews.json"

warnings_json=$(sort -u "$warnings" | jq -Rsc 'split("\n") | map(select(length > 0))')
review_count=$(jq 'length' "$tmp/reviews.json")
assigned_count=$(jq 'length' "$tmp/assigned.json")

if [[ $(jq 'length' <<<"$warnings_json") -gt 0 && $review_count -eq 0 && $assigned_count -eq 0 ]]; then
  state=error
else
  state=ready
fi

jq -n \
  --arg state "$state" \
  --slurpfile reviews "$tmp/reviews.json" \
  --slurpfile teamReviews "$tmp/team-reviews.json" \
  --slurpfile assigned "$tmp/assigned.json" \
  --argjson warnings "$warnings_json" \
  '{
    state: $state,
    message: "",
    fetchedAt: (now | todateiso8601),
    reviewRequests: $reviews[0],
    teamReviewRequests: $teamReviews[0],
    assignedPullRequests: $assigned[0],
    warnings: $warnings
  }'
