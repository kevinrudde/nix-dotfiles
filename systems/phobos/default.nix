{ pkgs
, home-manager
, flake
, lib
, config
, ...
}: {
  imports = [
    ../shared/aerospace.nix
    ../shared/brew.nix
    ../shared/system.nix
    ../shared/fonts.nix
  ];

  system.stateVersion = 5;
  system.primaryUser = "kevin";

  ids.gids.nixbld = 30000;

  users.users.kevin = {
    home = "/Users/kevin";
    shell = "${pkgs.fish}/bin/fish";
  };

  home-manager.users.kevin = {
    imports = [
      ../../home/phobos.nix
    ];
  };

  environment.systemPackages = with pkgs; [
    raycast
    obsidian
  ];

  nixpkgs.config.allowUnfree = true;

  programs.fish.enable = true;
  environment.shells = [ "${pkgs.fish}/bin/fish" ];

  documentation.enable = false;
  documentation.man.enable = false;

  time.timeZone = "Europe/Berlin";

  nix.enable = false;
}
