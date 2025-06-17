{ pkgs, lib, ... }:
{
  imports = [
    ./packages.nix
    ./keybindings
  ];
} 