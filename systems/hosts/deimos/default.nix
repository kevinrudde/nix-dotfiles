{ inputs, pkgs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  imports = [
    ../../features/hyprland
    ../../features/ashell
    ../../features/sddm
    ../../features/power-button
  ];

  nixSystem = {
    enable = true;
    hostName = "deimos";
    system = "aarch64-linux";
    backend = "fedora";
  };

  features.hyprland.hostConfig = ./hyprland.lua;

  features.ashell = {
    user = "kevin";
    homeDir = "/home/kevin";
  };

  dnf.onActivation = {
    cleanup = "none";
    autoUpdate = false;
    upgrade = false;
  };

  networking.hosts = { };

  environment.systemPackages = [
    inputs.nix-system.packages.${system}.nix-system
  ];

  environment.symlinks."/usr/local/bin/nix-system" =
    "/nix/var/nix/profiles/nix-system/bin/nix-system";
}
