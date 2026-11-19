#!/usr/bin/env bash
set -euo pipefail

state_file="${XDG_STATE_HOME:-$HOME/.local/state}/container-engine"
podman_socket="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/podman/podman.sock"

usage() {
  echo "usage: container-engine docker|podman|status" >&2
  exit 2
}

current_engine() {
  cat "$state_file" 2>/dev/null || echo docker
}

ensure_podman_context() {
  if ! docker context inspect podman >/dev/null 2>&1; then
    docker context create podman --docker "host=unix://$podman_socket" >/dev/null
  fi
}

case "${1:-}" in
  status)
    current_engine
    ;;
  docker)
    docker context use default >/dev/null
    mkdir -p "$(dirname "$state_file")"
    echo docker >"$state_file"
    echo "docker CLI -> rootful docker (docker.socket starts the daemon on demand)"
    ;;
  podman)
    ensure_podman_context
    systemctl --user enable --now podman.socket
    docker context use podman >/dev/null
    mkdir -p "$(dirname "$state_file")"
    echo podman >"$state_file"
    echo "docker CLI -> rootless podman ($podman_socket); kind uses its podman provider"
    ;;
  *)
    usage
    ;;
esac
