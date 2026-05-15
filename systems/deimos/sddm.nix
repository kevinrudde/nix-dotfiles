{
  dnf.packages = [
    "sddm"
    "sddm-wayland-generic"
  ];

  environment.etc."sddm.conf.d/10-deimos.conf".text = ''
    [General]
    DisplayServer=wayland

    [Wayland]
    CompositorCommand=weston --shell=kiosk
    SessionDir=/usr/share/wayland-sessions
  '';

  systemd.services.sddm.enable = true;

  system.activationScripts.sddm-graphical-target = {
    text = ''
      systemctl set-default graphical.target
    '';
    deps = [ ];
  };
}
