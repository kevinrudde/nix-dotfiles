{ config, pkgs, ... }:

{
  imports = [
    ./default.nix
  ];

  home.username = "kevin";
  home.homeDirectory = "/home/kevin";

  targets.genericLinux.enable = true;
}
