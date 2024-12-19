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
  ];

  home.username = "C.Hessel";
  home.homeDirectory = lib.mkForce "/Users/C.Hessel";
}
