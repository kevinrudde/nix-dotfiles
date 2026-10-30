#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/op-account-add.sh [--address ADDRESS] [--email EMAIL]

Adds a 1Password account to the CLI using `op` from nixpkgs. Prompts for the
secret key and master password, so run it in an interactive terminal.

Both flags are optional; op prompts for any value that is not given.
EOF
}

address=""
email=""

while (($# > 0)); do
  case "$1" in
    --address)
      shift
      address="${1:?missing value for --address}"
      shift
      ;;
    --email)
      shift
      email="${1:?missing value for --email}"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! -t 0 ]]; then
  echo "op account add needs an interactive terminal" >&2
  exit 1
fi

if [[ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
  # shellcheck source=/dev/null
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi
command -v nix >/dev/null 2>&1 || export PATH="/nix/var/nix/profiles/default/bin:$PATH"

add_args=(account add)
[[ -n "$address" ]] && add_args+=(--address "$address")
[[ -n "$email" ]] && add_args+=(--email "$email")

NIXPKGS_ALLOW_UNFREE=1 nix --extra-experimental-features 'nix-command flakes' \
  shell --impure nixpkgs#_1password-cli -c op "${add_args[@]}"
