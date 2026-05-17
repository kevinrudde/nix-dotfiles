{ ... }:

{
  xdg.configFile = {
    "mako/config".source = ./config;

    "systemd/user/mako.service.d/10-wayland-socket.conf".text = ''
      [Service]
      ExecCondition=
      ExecCondition=/bin/sh -c 'test -n "$WAYLAND_DISPLAY" && test -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"'
    '';
  };
}
