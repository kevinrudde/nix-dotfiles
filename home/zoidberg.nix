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
  ];

  home.username = "C.Hessel";
  home.homeDirectory = lib.mkForce "/Users/C.Hessel";
} 