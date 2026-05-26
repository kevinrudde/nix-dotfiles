#!/usr/bin/env bash
set -euo pipefail

# Migration: Install 1Password for Linux from the signed ARM tarball
# Host: deimos
#
# The 1Password RPM repository currently provides 1password-cli for aarch64,
# but not the desktop 1password package. The desktop app is installed from
# 1Password's official signed arm64 tarball.

case "$(uname -m)" in
  aarch64|arm64)
    archive_arch="aarch64"
    ;;
  *)
    echo "This migration expects an ARM64 Linux host, got: $(uname -m)" >&2
    exit 1
    ;;
esac

for command in curl gpg tar sudo; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "$command is required to install 1Password from the signed tarball." >&2
    exit 1
  fi
done

base_url="https://downloads.1password.com/linux/tar/stable/${archive_arch}"
archive_url="${base_url}/1password-latest.tar.gz"
signature_url="${archive_url}.sig"
key_url="https://downloads.1password.com/linux/keys/1password.asc"
expected_fingerprint="3FEF9748469ADBE15DA7CA80AC2D62742012EA22"
install_dir="/opt/1Password"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

archive_file="${tmp_dir}/1password-latest.tar.gz"
signature_file="${archive_file}.sig"
key_file="${tmp_dir}/1password.asc"
gpg_home="${tmp_dir}/gnupg"
extract_dir="${tmp_dir}/extract"

curl -fL --proto '=https' --tlsv1.2 -o "$archive_file" "$archive_url"
curl -fL --proto '=https' --tlsv1.2 -o "$signature_file" "$signature_url"
curl -fL --proto '=https' --tlsv1.2 -o "$key_file" "$key_url"

install -d -m 0700 "$gpg_home"

actual_fingerprint="$(gpg --batch --homedir "$gpg_home" --show-keys --with-colons "$key_file" | awk -F: '$1 == "fpr" { print toupper($10); exit }')"
if [[ "$actual_fingerprint" != "$expected_fingerprint" ]]; then
  echo "Unexpected 1Password signing key fingerprint: $actual_fingerprint" >&2
  echo "Expected: $expected_fingerprint" >&2
  exit 1
fi

gpg --batch --homedir "$gpg_home" --import "$key_file"
gpg --batch --homedir "$gpg_home" --verify "$signature_file" "$archive_file"

install -d -m 0755 "$extract_dir"
tar -xzf "$archive_file" -C "$extract_dir"

shopt -s nullglob
app_dirs=("${extract_dir}"/1password-*.arm64)
shopt -u nullglob

if [[ "${#app_dirs[@]}" -ne 1 ]]; then
  echo "Expected exactly one extracted 1Password app directory, found ${#app_dirs[@]}" >&2
  exit 1
fi

app_src="${app_dirs[0]}"

for required_file in 1password after-install.sh resources/1password.desktop; do
  if [[ ! -e "${app_src}/${required_file}" ]]; then
    echo "1Password tarball is missing required file: $required_file" >&2
    exit 1
  fi
done

sudo rm -rf "$install_dir"
sudo install -d -m 0755 "$install_dir"
sudo cp -a "${app_src}/." "$install_dir/"
sudo chown -R root:root "$install_dir"
sudo "$install_dir/after-install.sh"

installed_version="$(1password --version 2>/dev/null || true)"
if [[ -n "$installed_version" ]]; then
  echo "Installed 1Password ${installed_version} from the signed ARM tarball"
else
  echo "Installed 1Password from the signed ARM tarball"
fi
