{ pkgs
, home-manager
, lib
, config
, ...
}: {
  imports = [
    ../shared/yabai.nix
    ../shared/skhd.nix
    ../shared/brew.nix
    ../shared/system.nix
    ../shared/fonts.nix
  ];

  users.users.kevin = {
    home = "/Users/kevin";
    shell = "${pkgs.fish}/bin/fish";
  };

  home-manager.users.kevin = { imports = [
    ../../home/phobos.nix
  ];};


  nix = {
    settings.trusted-users = [ "root" "kevin" ];
  };

  nix.gc = {
    automatic = true;
    options = "--delete-older-than 2d";
    interval = {
      Hour = 5;
      Minute = 0;
    };
  };

  environment.systemPackages = with pkgs; [
    raycast
  ];

  services.nix-daemon.enable = true;
  nixpkgs.config.allowUnfree = true;

  programs.fish.enable = true;
  environment.shells = [ "${pkgs.fish}/bin/fish" ];

  documentation.enable = false;
  documentation.man.enable = false;

  time.timeZone = "Europe/Dublin";

  # Nix config from https://github.com/DeterminateSystems/nix-installer
  nix.settings.build-users-group = "nixbld";
  nix.settings.experimental-features = "nix-command flakes repl-flake";
  nix.settings.bash-prompt-prefix = "(nix:$name)\040";
  nix.settings.max-jobs = "auto";
  nix.settings.extra-nix-path = "nixpkgs=flake:nixpkgs";
}
