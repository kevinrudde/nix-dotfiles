#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/fedora-packages-sync.sh [--host HOST] [--repo DIR]

Enables host-specific Fedora COPR repositories listed in
systems/<host>/copr-repos.txt, installs host-specific DNF repository release
RPMs listed in systems/<host>/dnf-release-rpms.txt, enables host-specific DNF
repositories listed in systems/<host>/dnf-enabled-repos.txt, installs
host-specific RPM repository files from systems/<host>/dnf-repos, imports
host-specific RPM keys listed in systems/<host>/rpm-keys.txt, and installs
host-specific native packages listed in systems/<host>/packages.txt using dnf.
EOF
}

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
host="$(hostname -s 2>/dev/null || hostname)"

while (($# > 0)); do
  case "$1" in
    --host)
      shift
      host="${1:?missing value for --host}"
      shift
      ;;
    --repo)
      shift
      repo_root="${1:?missing value for --repo}"
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

packages_file="$repo_root/systems/$host/packages.txt"
copr_repos_file="$repo_root/systems/$host/copr-repos.txt"
rpm_keys_file="$repo_root/systems/$host/rpm-keys.txt"
dnf_release_rpms_file="$repo_root/systems/$host/dnf-release-rpms.txt"
dnf_enabled_repos_file="$repo_root/systems/$host/dnf-enabled-repos.txt"
dnf_repos_dir="$repo_root/systems/$host/dnf-repos"

if [[ ! -f "$packages_file" && ! -f "$copr_repos_file" && ! -f "$rpm_keys_file" && ! -f "$dnf_release_rpms_file" && ! -f "$dnf_enabled_repos_file" && ! -d "$dnf_repos_dir" ]]; then
  echo "No Fedora package, COPR, RPM key, or DNF repo definitions found for host '$host'"
  exit 0
fi

if command -v dnf5 >/dev/null 2>&1; then
  dnf_cmd="$(command -v dnf5)"
elif command -v dnf >/dev/null 2>&1; then
  dnf_cmd="$(command -v dnf)"
else
  echo "dnf or dnf5 is required to sync Fedora packages" >&2
  exit 1
fi

if ((EUID != 0)) && ! command -v sudo >/dev/null 2>&1; then
  echo "sudo is required to enable COPRs and install Fedora packages" >&2
  exit 1
fi

run_as_root() {
  if ((EUID == 0)); then
    "$@"
  else
    sudo "$@"
  fi
}

read_list() {
  local file="$1"

  if [[ -f "$file" ]]; then
    sed \
      -e 's/[[:space:]]*#.*$//' \
      -e 's/^[[:space:]]*//' \
      -e 's/[[:space:]]*$//' \
      -e '/^$/d' \
      "$file"
  fi
}

normalize_copr_repo() {
  local repo="$1"

  repo="${repo%%[[:space:]]*}"
  repo="${repo#copr.fedorainfracloud.org/}"
  printf '%s\n' "$repo"
}

array_contains() {
  local needle="$1"
  shift

  local item
  for item in "$@"; do
    if [[ "$item" == "$needle" ]]; then
      return 0
    fi
  done

  return 1
}

mapfile -t copr_repos < <(read_list "$copr_repos_file")
mapfile -t rpm_keys < <(read_list "$rpm_keys_file")
mapfile -t dnf_release_rpms < <(read_list "$dnf_release_rpms_file")
mapfile -t dnf_enabled_repos < <(read_list "$dnf_enabled_repos_file")
mapfile -t packages < <(read_list "$packages_file")

if [[ "${#rpm_keys[@]}" -gt 0 || "${#dnf_release_rpms[@]}" -gt 0 ]]; then
  if ! command -v rpm >/dev/null 2>&1; then
    echo "rpm is required to manage Fedora package repositories" >&2
    exit 1
  fi
fi

rpm_key_already_imported() {
  local key_source="$1"

  if ! command -v gpg >/dev/null 2>&1; then
    return 1
  fi

  local tmp_key
  tmp_key="$(mktemp)"

  if [[ "$key_source" =~ ^https?:// ]]; then
    if ! command -v curl >/dev/null 2>&1 || ! curl -fsSL "$key_source" -o "$tmp_key" 2>/dev/null; then
      rm -f "$tmp_key"
      return 1
    fi
  elif [[ -f "$key_source" ]]; then
    cp -- "$key_source" "$tmp_key"
  else
    rm -f "$tmp_key"
    return 1
  fi

  local fingerprint
  fingerprint="$(gpg --with-colons --import-options show-only --import "$tmp_key" 2>/dev/null \
    | awk -F: '/^fpr:/ {print $10; exit}')"
  rm -f "$tmp_key"

  if [[ -z "$fingerprint" ]]; then
    return 1
  fi

  local short_id
  short_id="$(printf '%s' "$fingerprint" | tr 'A-Z' 'a-z')"
  short_id="${short_id: -8}"

  rpm -q "gpg-pubkey-$short_id" >/dev/null 2>&1
}

if [[ "${#rpm_keys[@]}" -gt 0 ]]; then
  missing_rpm_keys=()
  for rpm_key in "${rpm_keys[@]}"; do
    if ! rpm_key_already_imported "$rpm_key"; then
      missing_rpm_keys+=("$rpm_key")
    fi
  done

  if [[ "${#missing_rpm_keys[@]}" -eq 0 ]]; then
    echo "Fedora RPM keys for '$host' are already imported"
  else
    echo "Importing missing Fedora RPM keys for '$host'"
    for rpm_key in "${missing_rpm_keys[@]}"; do
      echo "  $rpm_key"
      run_as_root rpm --import "$rpm_key"
    done
  fi
fi

if [[ "${#dnf_release_rpms[@]}" -gt 0 ]]; then
  fedora_release="$(rpm -E %fedora)"
  missing_dnf_release_rpms=()

  for dnf_release_rpm in "${dnf_release_rpms[@]}"; do
    read -r release_package release_url extra <<<"$dnf_release_rpm"

    if [[ -z "${release_package:-}" || -z "${release_url:-}" || -n "${extra:-}" ]]; then
      echo "Invalid DNF release RPM entry in $dnf_release_rpms_file: $dnf_release_rpm" >&2
      echo "Expected: <installed-package-name> <rpm-url>" >&2
      exit 1
    fi

    if ! rpm -q "$release_package" >/dev/null 2>&1; then
      release_url="${release_url//\{fedora\}/$fedora_release}"
      missing_dnf_release_rpms+=("$release_url")
    fi
  done

  if [[ "${#missing_dnf_release_rpms[@]}" -eq 0 ]]; then
    echo "Fedora DNF release RPMs for '$host' are already installed"
  else
    echo "Installing missing Fedora DNF release RPMs for '$host'"
    run_as_root "$dnf_cmd" -y install "${missing_dnf_release_rpms[@]}"
  fi
fi

if [[ "${#dnf_enabled_repos[@]}" -gt 0 ]]; then
  if ! "$dnf_cmd" config-manager --help >/dev/null 2>&1; then
    echo "dnf config-manager support is required to enable repositories from $dnf_enabled_repos_file" >&2
    exit 1
  fi

  if ! enabled_repos_output="$("$dnf_cmd" repolist --enabled 2>/dev/null)"; then
    echo "Unable to list enabled Fedora DNF repositories" >&2
    exit 1
  fi

  enabled_repos=()
  while IFS= read -r repo_line; do
    repo_id="${repo_line%%[[:space:]]*}"
    if [[ -z "$repo_id" || "$repo_id" == "repo" ]]; then
      continue
    fi
    enabled_repos+=("$repo_id")
  done <<<"$enabled_repos_output"

  missing_dnf_enabled_repos=()
  for dnf_enabled_repo in "${dnf_enabled_repos[@]}"; do
    if ! array_contains "$dnf_enabled_repo" "${enabled_repos[@]}"; then
      missing_dnf_enabled_repos+=("$dnf_enabled_repo")
    fi
  done

  if [[ "${#missing_dnf_enabled_repos[@]}" -eq 0 ]]; then
    echo "Fedora DNF repositories for '$host' are already enabled"
  else
    echo "Enabling missing Fedora DNF repositories for '$host'"
    for dnf_enabled_repo in "${missing_dnf_enabled_repos[@]}"; do
      echo "  $dnf_enabled_repo"

      if "$dnf_cmd" config-manager enable --help >/dev/null 2>&1; then
        run_as_root "$dnf_cmd" config-manager enable "$dnf_enabled_repo"
      else
        run_as_root "$dnf_cmd" config-manager --set-enabled "$dnf_enabled_repo"
      fi
    done
  fi
fi

if [[ -d "$dnf_repos_dir" ]]; then
  mapfile -t dnf_repo_files < <(find "$dnf_repos_dir" -maxdepth 1 -type f -name '*.repo' -print | LC_ALL=C sort)

  if [[ "${#dnf_repo_files[@]}" -gt 0 ]]; then
    missing_dnf_repo_files=()
    for dnf_repo_file in "${dnf_repo_files[@]}"; do
      repo_target="/etc/yum.repos.d/$(basename "$dnf_repo_file")"

      if [[ ! -f "$repo_target" ]] || ! cmp -s "$dnf_repo_file" "$repo_target"; then
        missing_dnf_repo_files+=("$dnf_repo_file")
      fi
    done

    if [[ "${#missing_dnf_repo_files[@]}" -eq 0 ]]; then
      echo "Fedora DNF repository files for '$host' are already installed"
    else
      echo "Installing missing Fedora DNF repository files for '$host'"
      for dnf_repo_file in "${missing_dnf_repo_files[@]}"; do
        repo_target="/etc/yum.repos.d/$(basename "$dnf_repo_file")"
        echo "  $(basename "$dnf_repo_file")"
        run_as_root install -D -m 0644 "$dnf_repo_file" "$repo_target"
      done
    fi
  fi
fi

if [[ "${#copr_repos[@]}" -gt 0 ]]; then
  if ! "$dnf_cmd" copr --help >/dev/null 2>&1; then
    echo "dnf COPR support is required to enable repositories from $copr_repos_file" >&2
    echo "Install the COPR plugin package for your dnf version, then rerun this script." >&2
    exit 1
  fi

  if ! enabled_copr_output="$("$dnf_cmd" copr list)"; then
    echo "Unable to list enabled Fedora COPR repositories" >&2
    exit 1
  fi

  enabled_copr_repos=()
  while IFS= read -r enabled_copr_repo; do
    normalized_copr_repo="$(normalize_copr_repo "$enabled_copr_repo")"

    if [[ "$normalized_copr_repo" == */* ]]; then
      enabled_copr_repos+=("$normalized_copr_repo")
    fi
  done <<<"$enabled_copr_output"

  missing_copr_repos=()
  for copr_repo in "${copr_repos[@]}"; do
    normalized_copr_repo="$(normalize_copr_repo "$copr_repo")"

    if ! array_contains "$normalized_copr_repo" "${enabled_copr_repos[@]}"; then
      missing_copr_repos+=("$copr_repo")
    fi
  done

  if [[ "${#missing_copr_repos[@]}" -eq 0 ]]; then
    echo "Fedora COPR repositories for '$host' are already enabled"
  else
    echo "Enabling missing Fedora COPR repositories for '$host'"
  fi

  for copr_repo in "${missing_copr_repos[@]}"; do
    echo "  $copr_repo"
    run_as_root "$dnf_cmd" -y copr enable "$copr_repo"
  done
fi

if [[ "${#packages[@]}" -eq 0 ]]; then
  if [[ -f "$packages_file" ]]; then
    echo "No Fedora packages listed in $packages_file"
  fi
  exit 0
fi

if ! command -v rpm >/dev/null 2>&1; then
  echo "rpm is required to check installed Fedora packages" >&2
  exit 1
fi

missing_packages=()

for package in "${packages[@]}"; do
  if ! rpm -q "$package" >/dev/null 2>&1 \
    && ! rpm -q --whatprovides "$package" >/dev/null 2>&1; then
    missing_packages+=("$package")
  fi
done

if [[ "${#missing_packages[@]}" -eq 0 ]]; then
  echo "Fedora packages for '$host' are already installed"
  exit 0
fi

echo "Installing missing Fedora packages for '$host' via dnf"
run_as_root "$dnf_cmd" -y install --allowerasing "${missing_packages[@]}"
