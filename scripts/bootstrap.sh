#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/bootstrap.sh [--account ACCOUNT] [--vault VAULT] [--item ITEM] [--field FIELD] [--force]

Installs Determinate Nix (if missing), paru (on Arch-based hosts, if missing)
and restores the sops age key from
1Password into the location expected by home/features/secrets.

Defaults:
  --item   "nix-sops age key"
  --field  ".config/sops/age/keys.txt"
  --account none (op default; pass a shorthand or URL from `op account list`)
  --vault  none (1Password searches all vaults of the account)

Existing key files are kept unless --force is passed.
EOF
}

item="nix-sops age key"
field=".config/sops/age/keys.txt"
vault=""
account=""
force=0

while (($# > 0)); do
  case "$1" in
    --account)
      shift
      account="${1:?missing value for --account}"
      shift
      ;;
    --vault)
      shift
      vault="${1:?missing value for --vault}"
      shift
      ;;
    --item)
      shift
      item="${1:?missing value for --item}"
      shift
      ;;
    --field)
      shift
      field="${1:?missing value for --field}"
      shift
      ;;
    --force)
      force=1
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

if [[ "$(uname -s)" == "Darwin" ]]; then
  age_key_file="$HOME/Library/Application Support/sops/age/keys.txt"
else
  age_key_file="$HOME/.config/sops/age/keys.txt"
fi

nix_daemon_profile=/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

install_nix() {
  if command -v nix >/dev/null 2>&1; then
    return
  fi

  if [[ ! -e /nix/var/nix/profiles/default/bin/nix ]]; then
    echo "Installing Determinate Nix"
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix |
      sh -s -- install --no-confirm
  fi

  if [[ -r "$nix_daemon_profile" ]]; then
    # shellcheck source=/dev/null
    . "$nix_daemon_profile"
  fi
  command -v nix >/dev/null 2>&1 || export PATH="/nix/var/nix/profiles/default/bin:$PATH"
}

# 1Password CLI is unfree, so it is run through nix instead of being installed
# system-wide; the bootstrap leaves no extra package behind.
run_unfree() {
  NIXPKGS_ALLOW_UNFREE=1 nix --extra-experimental-features 'nix-command flakes' \
    shell --impure nixpkgs#_1password-cli nixpkgs#jq -c "$@"
}

fetch_age_key() {
  local get_args=(item get "$item" --format json)
  [[ -n "$account" ]] && get_args+=(--account "$account")
  [[ -n "$vault" ]] && get_args+=(--vault "$vault")

  if ! op account list >/dev/null 2>&1 || [[ -z "$(op account list 2>/dev/null)" ]]; then
    echo "No 1Password account configured; run 'op account add' or enable desktop app integration." >&2
    return 1
  fi

  local whoami_args=() signin_args=()
  [[ -n "$account" ]] && whoami_args=(--account "$account") && signin_args=(--account "$account")
  if ! op whoami "${whoami_args[@]}" >/dev/null 2>&1; then
    eval "$(op signin "${signin_args[@]}")"
  fi

  op "${get_args[@]}" | jq -er --arg field "$field" '
    [.fields[]? | select(.label == $field or .id == $field) | .value | select(. != null and . != "")][0]
    // error("field not found: " + $field)
  '
}

write_age_key() {
  install -d -m 700 "$(dirname "$age_key_file")"
  (
    umask 077
    cat >"$age_key_file"
  )
  chmod 600 "$age_key_file"
}

# Arch-based hosts need paru for scripts/paru-sync.sh; it is not in the official
# repos, so build the prebuilt-binary AUR package once.
install_paru() {
  command -v pacman >/dev/null 2>&1 || return 0
  command -v paru >/dev/null 2>&1 && return 0

  echo "Installing paru"
  sudo pacman -S --needed --noconfirm base-devel git
  local build_dir
  build_dir="$(mktemp -d)"
  git clone --depth 1 https://aur.archlinux.org/paru-bin.git "$build_dir/paru-bin"
  (cd "$build_dir/paru-bin" && makepkg -si --noconfirm)
  rm -rf "$build_dir"
}

install_nix
install_paru

if [[ -s "$age_key_file" && $force -eq 0 ]]; then
  echo "Age key already present at $age_key_file (use --force to replace)"
  exit 0
fi

export -f fetch_age_key
export item field vault account
age_key="$(run_unfree bash -c 'fetch_age_key')"

if ! grep -q '^AGE-SECRET-KEY-' <<<"$age_key"; then
  echo "Fetched value does not look like an age key" >&2
  exit 1
fi

printf '%s\n' "$age_key" | write_age_key
echo "Age key written to $age_key_file"
