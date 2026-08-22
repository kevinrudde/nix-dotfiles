{ pkgs, ... }:

let
  # Native build rather than nixpkgs': vicinae draws its window with Qt Quick,
  # i.e. OpenGL, and on a generic-linux home-manager host there is no
  # /run/opengl-driver for the Nix build's libEGL to find the system Mesa ICDs
  # through. The server then aborts with "Failed to initialize graphics backend
  # for OpenGL" the moment the window is created -- and because only the
  # rendering half dies, the daemon stays up and answers IPC, so `vicinae
  # toggle` exits 0 and silently does nothing. The distro build links the system
  # Mesa directly. Same reasoning that keeps quickshell on the native package.
  #
  # Home-manager still owns the config and the user unit; only the binary is
  # native (vicinae-bin, in systems/hyperion/packages.txt). The unit below
  # shadows the /usr/lib/systemd/user/vicinae.service that package ships, since
  # units under ~/.config take precedence.
  vicinae = "/usr/bin/vicinae";

  settingsFormat = pkgs.formats.json { };
in
{
  xdg.configFile."vicinae/settings.json".source = settingsFormat.generate "vicinae-settings" {
    # Same family as the bar and the Qt/GTK app theming, rather than vicinae's
    # bundled Inter.
    font.normal.family = "JetBrains Mono";

    # Vicinae ships tokyo-night among its built-in themes, and it is the palette
    # Quickshell's Theme.qml is built from -- so the launcher reads as the same
    # surface as the bar. Both appearances are pinned to it: this desktop is
    # dark-only, and leaving `light` at the default would flip the launcher to
    # vicinae's own gold theme if anything ever reported a light appearance.
    theme = {
      dark.name = "tokyo-night";
      light.name = "tokyo-night";
    };

    # A launcher that stays up after losing focus is a window to dismiss by
    # hand; close it instead.
    close_on_focus_loss = true;

    # Vicinae's own default config documents 'exclusive' keyboard interactivity
    # as breaking mouse input on its popovers (the action panel) under Hyprland.
    # 'on_demand' avoids that, and is what makes close_on_focus_loss above
    # meaningful -- an exclusive layer surface never reports focus loss.
    launcher_window.layer_shell.keyboard_interactivity = "on_demand";
  };

  # graphical-session.target is only reached once `uwsm finalize` has published
  # WAYLAND_DISPLAY into the user manager (systems/shared/hypr/conf/autostart.lua),
  # so the daemon always comes up with a display to bind its layer surface to.
  systemd.user.services.vicinae = {
    Unit = {
      Description = "Vicinae launcher daemon";
      Documentation = [ "https://docs.vicinae.com" ];
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${vicinae} server";
      Restart = "always";
      RestartSec = 5;
      KillMode = "process";
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
