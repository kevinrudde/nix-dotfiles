{
  environment.etc."systemd/logind.conf.d/10-deimos-power.conf".text = ''
    [Login]
    HandlePowerKey=ignore
    HandlePowerKeyLongPress=ignore
  '';

  environment.files."/usr/local/bin/deimos-power-button-action" = {
    source = ./bin/power-button-action.sh;
    mode = "0755";
  };

  system.activationScripts.reload-logind = {
    text = ''
      systemctl kill -s HUP systemd-logind.service
    '';
    deps = [ ];
  };
}
