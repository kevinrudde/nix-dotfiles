{ pkgs, lib, config, ... }:
{
  # Mise supplies fast-moving developer tools independently of nixpkgs.
  home.packages = [ pkgs.mise ];

  xdg.configFile."mise/config.toml" = {
    source = ./config.toml;
    force = true;
  };

  # Run after the profile and configuration symlinks exist. `install` handles
  # newly declared tools; `upgrade` refreshes the versions already installed.
  home.activation.upgradeMiseTools = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    mise="${config.home.profileDirectory}/bin/mise"
    $DRY_RUN_CMD "$mise" install --yes
    $DRY_RUN_CMD "$mise" upgrade --yes
  '';
}
