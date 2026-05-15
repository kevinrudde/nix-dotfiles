{ pkgs, lib, config, ... }:

let
  cfg = config.features.hyprland;
  hostName = config.nixSystem.hostName;

  hyprlandConfig = pkgs.runCommand "hyprland-lua-${hostName}" { } ''
    mkdir -p $out
    cp -r ${./lua}/. $out/
    ${
      if cfg.hostConfig != null
      then "install -m 0644 ${cfg.hostConfig} $out/host.lua"
      else "printf '%s\\n' '-- no host-specific config' > $out/host.lua"
    }
  '';

  envFile = pkgs.writeText "uwsm-env-hyprland" ''
    export MOZ_ENABLE_WAYLAND=1
    export ELECTRON_OZONE_PLATFORM_HINT=auto
    export SDL_VIDEODRIVER=wayland
    export CLUTTER_BACKEND=wayland
    export GTK_USE_PORTAL=1
    export QT_QPA_PLATFORM="wayland;xcb"
    export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
  '';

  launcher = pkgs.writeShellApplication {
    name = "start-hyprland-session";
    text = ''
      exec uwsm start -e -D Hyprland -- start-hyprland -- --config ${hyprlandConfig}/init.lua
    '';
  };
in
{
  options.features.hyprland = {
    hostConfig = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Optional host-specific Hyprland Lua module. Copied into the generated
        config directory as `host.lua` and required by `init.lua` before any
        shared modules, so it's the place to declare per-machine monitors,
        workspace rules, etc.
      '';
    };
  };

  config = {
    dnf.packages = [
      "foot"
      "fuzzel"
      "mako"
      "wireplumber"
      "wl-clipboard"
      "grim"
      "slurp"
      "brightnessctl"
      "playerctl"
      "qt5-qtwayland"
      "qt6-qtwayland"
    ];

    copr = {
      repositories = [
        "lionheartp/Hyprland"
      ];

      packages = [
        "hyprland"
        "uwsm"
        "hypridle"
        "hyprlock"
        "xdg-desktop-portal-hyprland"
      ];
    };

    environment.systemPackages = [ launcher ];

    environment.files."/etc/xdg/uwsm/env-hyprland" = {
      source = envFile;
      mode = "0644";
    };

    environment.files."/usr/share/wayland-sessions/hyprland-${hostName}-uwsm.desktop" = {
      text = ''
        [Desktop Entry]
        Name=Hyprland (UWSM, ${hostName})
        Comment=Hyprland session managed by Universal Wayland Session Manager
        Exec=${launcher}/bin/start-hyprland-session
        TryExec=uwsm
        Type=Application
        DesktopNames=Hyprland
      '';
      mode = "0644";
    };
  };
}
