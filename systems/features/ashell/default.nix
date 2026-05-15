{ lib, config, ... }:

let
  cfg = config.features.ashell;
in
{
  options.features.ashell = {
    user = lib.mkOption {
      type = lib.types.str;
      description = "User that owns the deployed ashell config.";
    };

    homeDir = lib.mkOption {
      type = lib.types.str;
      description = "Home directory of `user`. Config is deployed under `homeDir/.config/ashell/`.";
    };
  };

  config = {
    copr = {
      repositories = [
        "killcrb/ashell"
      ];

      packages = [
        "ashell"
      ];
    };

    environment.files."${cfg.homeDir}/.config/ashell/config.toml" = {
      source = ./config.toml;
      user = cfg.user;
      group = cfg.user;
      mode = "0644";
    };
  };
}
