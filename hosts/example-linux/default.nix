{ config, pkgs, lib, ... }: {

  imports = [
    ../shared/fonts.nix
    # Add Linux-specific modules here when created
    # ../../modules/nixos/desktop
    # ../../modules/nixos/window-managers
  ];

  # System configuration
  system.stateVersion = "24.05";
  
  # User configuration
  users.users."C.Hessel" = {
    isNormalUser = true;
    home = "/home/C.Hessel";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
    shell = pkgs.fish;
  };

  # Enable common services
  programs.fish.enable = true;
  
  # Nix configuration
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "C.Hessel" ];
    auto-optimise-store = true;
  };

  nixpkgs.config.allowUnfree = true;

  # Basic system packages
  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
  ];

  # Networking
  networking.networkmanager.enable = true;

  # Time zone
  time.timeZone = "Europe/Berlin";

  # Internationalization
  i18n.defaultLocale = "en_US.UTF-8";
} 