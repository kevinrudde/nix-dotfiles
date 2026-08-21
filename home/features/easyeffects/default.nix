{ ... }:

let
  # Filename stem doubles as the preset name EasyEffects shows and as the
  # value the autoload profile below has to match.
  presetName = "xps16-speakers";

  # EasyEffects keys autoload profiles by "<node.name>:<route>.json", where
  # route is the route DESCRIPTION, not its name -- stream_output_effects.cpp
  # passes node.device_route_description into Manager::autoload() at all three
  # call sites. For this port PipeWire reports name='[Out] Speaker' but
  # description='Speaker'; keying on the name matches nothing and the preset
  # silently never loads. Confirm both halves against the live graph:
  #   pactl list sinks -> Name: alsa_output...HiFi__Speaker__sink
  #   pw-dump | jq '.[].info.params.Route[]? | select(.direction=="Output")'
  speakerNode = "alsa_output.pci-0000_00_1f.3-platform-sof_sdw.HiFi__Speaker__sink";
  speakerRoute = "Speaker";
in
{
  # EasyEffects 8 moved presets out of XDG_CONFIG_HOME into XDG_DATA_HOME
  # (QStandardPaths::AppDataLocation); the old ~/.config/easyeffects/output
  # path is only read by its one-shot migration. Hence dataFile, not
  # configFile.
  xdg.dataFile = {
    "easyeffects/output/${presetName}.json".source = ./xps16-speakers.json;

    # Autoload binds the preset to the internal speakers only. Headphones and
    # HDMI keep a flat chain -- this curve is cut for the built-in drivers and
    # would sound wrong on anything else.
    "easyeffects/autoload/output/${speakerNode}:${speakerRoute}.json".text = builtins.toJSON {
      device = speakerNode;
      device-description = "Speaker";
      device-profile = speakerRoute;
      preset-name = presetName;
    };
  };

  # Service mode runs the PipeWire filter chain without a window. Bound to
  # graphical-session.target so UWSM starts and stops it with the Hyprland
  # session, the same lifetime the compositor-launched helpers get from
  # systems/shared/hypr/conf/autostart.lua.
  systemd.user.services.easyeffects = {
    Unit = {
      Description = "EasyEffects audio processing";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "easyeffects --service-mode --hide-window";
      Restart = "on-failure";
      RestartSec = 5;
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
