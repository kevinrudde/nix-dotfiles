{ config
, pkgs
, lib
, flake
, ... }:

{
  imports = [
    flake.inputs.mac-app-util.homeManagerModules.default
    ./default.nix
    ./features/darwin
    ./features/hammerspoon
    ./features/skhd
  ];

  home.username = "kevin";
  home.homeDirectory = lib.mkForce "/Users/kevin";
}
