{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./default.nix
    ./features/ghostty
    ./features/hypr
    ./features/quickshell
    ./features/theme
  ];

  home.username = "kevin";
  home.homeDirectory = "/home/kevin";

  nixpkgs.config.allowUnfree = true;

  targets.genericLinux.enable = true;

  services.ssh-agent.enable = true;

  programs.ghostty.settings = {
    mouse-scroll-multiplier = "precision:0.1,discrete:1";
    quit-after-last-window-closed = true;
    quit-after-last-window-closed-delay = "5m";
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*".AddKeysToAgent = "yes";
  };
}
