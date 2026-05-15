let
  dotfilesRoot = "/home/kevin/.config/nix-dotfiles";
  launcher = "/usr/local/bin/start-hyprland-session";
in
{
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

  environment.files = {
    "${launcher}" = {
      source = ./bin/start-hyprland-session.sh;
      mode = "0755";
    };

    "/usr/share/wayland-sessions/hyprland-deimos-uwsm.desktop" = {
      text = ''
        [Desktop Entry]
        Name=Hyprland (UWSM, deimos)
        Comment=Hyprland session managed by Universal Wayland Session Manager
        Exec=/usr/bin/env DOTFILES_REPO_ROOT=${dotfilesRoot} ${launcher}
        TryExec=uwsm
        Type=Application
        DesktopNames=Hyprland
      '';
      mode = "0644";
    };
  };
}
