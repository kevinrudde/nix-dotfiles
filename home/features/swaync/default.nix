{ ... }:

{
  xdg.configFile = {
    "swaync/config.json".source = ./config.json;
    "swaync/style.css".source = ./style.css;

    "systemd/user/swaync.service.d/10-wayland-socket.conf".text = ''
      [Service]
      ExecCondition=
      ExecCondition=/bin/sh -c 'test -n "$WAYLAND_DISPLAY" && test -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"'
    '';
  };
}
