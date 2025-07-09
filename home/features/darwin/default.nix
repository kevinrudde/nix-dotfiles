{ pkgs, lib, ... }:
{
  imports = [
    ./packages.nix
    ./keybindings
    ./shell.nix
  ];
} 