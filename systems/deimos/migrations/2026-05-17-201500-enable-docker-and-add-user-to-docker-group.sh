#!/usr/bin/env bash
set -euo pipefail

# Migration: Enable Docker Engine and add the active user to the docker group
# Host: deimos
#
# The docker-ce repo (systems/deimos/dnf-repos/docker-ce.repo) and the
# docker-ce / docker-ce-cli / containerd.io / docker-buildx-plugin /
# docker-compose-plugin packages are installed by scripts/fedora-packages-sync.sh
# before migrations run, so this migration only handles the post-install
# steps from https://docs.docker.com/engine/install/linux-postinstall/.

host="${DOTFILES_MIGRATION_HOST:?missing host}"

if [[ "$host" != "deimos" ]]; then
  echo "This migration is for deimos, but the active host is $host" >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is not installed. Run scripts/rebuild-system.sh so native packages sync before migrations." >&2
  exit 1
fi

target_user="${SUDO_USER:-$(id -un)}"

if [[ "$target_user" == "root" ]]; then
  echo "Refusing to add 'root' to the docker group. Run this migration as your normal user." >&2
  exit 1
fi

sudo systemctl enable --now docker.service
sudo systemctl enable --now containerd.service

if ! getent group docker >/dev/null; then
  sudo groupadd docker
fi

if id -nG "$target_user" | tr ' ' '\n' | grep -Fxq docker; then
  echo "User '$target_user' is already in the docker group"
else
  sudo usermod -aG docker "$target_user"
  echo "Added '$target_user' to the docker group. Log out and back in (or run 'newgrp docker') for it to take effect."
fi
