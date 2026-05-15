{ pkgs, ... }:

let
  action = pkgs.writeShellApplication {
    name = "power-button-action";
    text = ''
      lock_dir="''${XDG_RUNTIME_DIR:-/tmp}/power-button-action.lock"
      if ! mkdir "$lock_dir" 2>/dev/null; then
        exit 0
      fi
      trap 'rmdir "$lock_dir"' EXIT

      hyprctl dispatch dpms on >/dev/null 2>&1 || true

      if pgrep -x hyprlock >/dev/null 2>&1; then
        exit 0
      fi

      if command -v uwsm >/dev/null 2>&1; then
        uwsm app -- hyprlock
        exit 0
      fi

      hyprlock
    '';
  };
in
{
  environment.etc."systemd/logind.conf.d/10-power-button.conf".text = ''
    [Login]
    HandlePowerKey=ignore
    HandlePowerKeyLongPress=ignore
  '';

  environment.systemPackages = [ action ];

  environment.symlinks."/usr/local/bin/power-button-action" =
    "/nix/var/nix/profiles/nix-system/bin/power-button-action";

  system.activationScripts.reload-logind = {
    text = ''
      systemctl kill -s HUP systemd-logind.service
    '';
    deps = [ ];
  };
}
