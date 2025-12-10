{ config, pkgs, ... }:

{
  imports = [
    ./default.nix
    ./features/anyrun
  ];

  home.username = "kevin";
  home.homeDirectory = "/home/kevin";

  targets.genericLinux.enable = true;
}
