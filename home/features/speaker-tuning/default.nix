{ ... }:

let
  # The config name `pipewire -c` resolves against $XDG_CONFIG_HOME/pipewire,
  # so the file name and the ExecStart argument have to stay in step.
  configName = "xps16-speaker-tuning.conf";
in
{
  # Deliberately not PipeWire's stock filter-chain.conf: that config merges every
  # fragment in filter-chain.conf.d/, so hosting the tuning there would make this
  # service run any unrelated filter that ever lands in that directory.
  xdg.configFile."pipewire/${configName}".source = ./xps16-speakers.conf;

  systemd.user.services.speaker-tuning = {
    Unit = {
      Description = "Dell XPS 16 speaker tuning filter-chain";
      # WirePlumber does the linking, so starting before it is up risks the
      # output being linked before the speaker device has been discovered.
      After = [ "pipewire.service" "wireplumber.service" ];
      Requires = [ "pipewire.service" ];
      Wants = [ "wireplumber.service" ];
      # The filter-chain loses its connection when PipeWire goes away, so it has
      # to come back with it.
      PartOf = [ "pipewire.service" "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      # The system PipeWire, not a Nix one: this hosts nodes inside the running
      # session daemon, and the two have to be the same build.
      ExecStart = "/usr/bin/pipewire -c ${configName}";
      Restart = "on-failure";
      RestartSec = 2;
    };

    # Same lifetime the compositor-launched helpers get from
    # systems/shared/hypr/conf/autostart.lua.
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
