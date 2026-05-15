{ inputs, pkgs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  imports = [
    ./ashell.nix
    ./hyprland.nix
    ./power.nix
    ./sddm.nix
  ];

  nixSystem = {
    enable = true;
    hostName = "deimos";
    system = "aarch64-linux";
    backend = "fedora";
  };

  dnf.onActivation = {
    cleanup = "none";
    autoUpdate = false;
    upgrade = false;
  };

  networking.hosts = { };

  environment.systemPackages = [
    inputs.nix-system.packages.${system}.nix-system
    pkgs.ashell
  ];

  environment.symlinks."/usr/local/bin/nix-system" = "/nix/var/nix/profiles/nix-system/bin/nix-system";
}
