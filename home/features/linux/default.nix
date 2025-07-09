{ pkgs, lib, ... }:
{
  imports = [
    ./packages.nix
    ./shell.nix
    # Future Linux-specific features will go here
    # ./window-managers
    # ./desktop-environments
  ];
} 