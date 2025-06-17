{ pkgs, lib, ... }:
{
  imports = [
    ./packages.nix
    # Future Linux-specific features will go here
    # ./window-managers
    # ./desktop-environments
  ];
} 