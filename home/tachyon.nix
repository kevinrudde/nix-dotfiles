{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./default.nix
    ./features/ghostty
    ./features/hypr
    ./features/quickshell
    ./features/theme
    ./features/vicinae
  ];

  home.username = "kevin";
  home.homeDirectory = "/home/kevin";

  nixpkgs.config.allowUnfree = true;

  targets.genericLinux.enable = true;
}
