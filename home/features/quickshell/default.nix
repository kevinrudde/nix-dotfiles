{ lib, ... }:

let
  # Quickshell derives QML module names from the directory names below the shell
  # root: `bar/` becomes `qs.bar`, `widgets/` becomes `qs.widgets`. Linked
  # recursively rather than as one symlink to the store path, so those are real
  # directories holding individual symlinks.
  shellConfig = ./shell;
in
{
  xdg.configFile."quickshell/shell" = {
    source = shellConfig;
    recursive = true;
  };

  # Picks up QML changes that live reload misses, e.g. new singletons or
  # processes. Only restarts a bar that is already running in a Wayland
  # session, and mirrors the launch line in systems/shared/hypr/conf/autostart.lua.
  home.activation.restartQuickshell = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if [ -n "''${WAYLAND_DISPLAY:-}" ] && /usr/bin/pgrep -x quickshell >/dev/null; then
      $DRY_RUN_CMD /usr/bin/quickshell kill --config shell || true
      # kill is asynchronous and --no-duplicate makes the new instance exit if
      # the old one is still alive, so wait for it to be gone first.
      for _ in $(seq 50); do
        /usr/bin/pgrep -x quickshell >/dev/null || break
        sleep 0.1
      done
      # The activation PATH is Nix-only: uwsm needs systemd-run from /usr/bin and
      # the shell's own tools (gh, ...) need the session PATH, so hand the
      # bar the one the user manager holds.
      session_path="$(/usr/bin/systemctl --user show-environment | sed -n 's/^PATH=//p')"
      $DRY_RUN_CMD /usr/bin/setsid -f /usr/bin/env PATH="''${session_path:-/usr/bin:$PATH}" /usr/bin/uwsm app -- env QT_QPA_PLATFORMTHEME=gtk3 QT_STYLE_OVERRIDE= \
        /usr/bin/quickshell --no-duplicate --config shell >/dev/null 2>&1 </dev/null || true
    fi
  '';
}
