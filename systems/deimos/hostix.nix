{ dotfilesRepoRoot, ... }:

{
  hostix.host = {
    name = "deimos";
    platform = "arch";
    arch = "x86_64-linux";
  };

  hostix.packages = {
    pacman = [
      "hyprland"
      "uwsm"
      "foot"
      "fuzzel"
      "mako"
      "wireplumber"
      "wl-clipboard"
      "grim"
      "slurp"
      "brightnessctl"
      "playerctl"
      "hypridle"
      "hyprlock"
      "xdg-desktop-portal-hyprland"
      "xdg-desktop-portal-gtk"
      "qt5-wayland"
      "qt6-wayland"
    ];

    aurHelper = "paru";
  };

  hostix.files."/usr/local/share/wayland-sessions/hyprland-deimos-uwsm.desktop" = {
    text = ''
      [Desktop Entry]
      Name=Hyprland (UWSM, deimos)
      Comment=Hyprland session managed by Universal Wayland Session Manager
      Exec=${dotfilesRepoRoot}/systems/deimos/bin/start-hyprland-session.sh
      Type=Application
      DesktopNames=Hyprland
    '';
    mode = "0644";
    owner = "root";
    group = "root";
  };

  hostix.homeManager = {
    enable = true;
    flakeAttr = "kevin@deimos";
    extraArgs = [ "--impure" ];
  };
}
