{ config, ... }:

{
  xdg.configFile = {
    "swaync/config.json".source = ./config.json;
    "swaync/style.css".source = ./style.css;

    # SwayNC is started by Hyprland through UWSM. Mask the packaged user unit so
    # D-Bus activation cannot race that process and report a failed service.
    "systemd/user/swaync.service".source = config.lib.file.mkOutOfStoreSymlink "/dev/null";
  };
}
