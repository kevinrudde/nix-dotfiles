{ config, pkgs, lib, inputs, ... }:

let
  flavor = "mocha";
  accent = "sky";
  gtkTheme = {
    name = "catppuccin-${flavor}-${accent}-standard";
    package = pkgs.catppuccin-gtk.override {
      variant = flavor;
      accents = [ accent ];
    };
  };
  iconTheme = {
    name = "Papirus-Dark";
    package = pkgs.catppuccin-papirus-folders.override {
      inherit flavor accent;
    };
  };
in
{
  imports = [
    ./default.nix
    ./features/hypr
    ./features/swaync
    ./features/waybar
  ];

  home.username = "kevin";
  home.homeDirectory = "/home/kevin";

  nixpkgs.config.allowUnfree = true;

  targets.genericLinux.enable = true;

  services.ssh-agent.enable = true;

  programs.ghostty.settings.mouse-scroll-multiplier = "precision:0.1,discrete:1";

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."*".addKeysToAgent = "yes";
  };

  gtk = {
    enable = true;
    theme = gtkTheme;
    iconTheme = iconTheme;
    colorScheme = "dark";

    gtk4 = {
      theme = gtkTheme;
      iconTheme = iconTheme;
    };
  };

  xdg.configFile."wireplumber/wireplumber.conf.d/51-bluez-avrcp.conf".text = ''
    monitor.bluez.properties = {
      bluez5.dummy-avrcp-player = true
    }
  '';

  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "kvantum";

    kvantum = {
      enable = true;
      themes = [
        (pkgs.catppuccin-kvantum.override {
          variant = flavor;
          inherit accent;
        })
      ];
      settings.General.theme = "catppuccin-${flavor}-${accent}";
    };
  };

  home.packages = with pkgs; [
    catppuccin-qt5ct
    libsForQt5.qt5ct
    qt6Packages.qt6ct
  ];

  xdg.desktopEntries.slack = {
    name = "Slack";
    exec = "uwsm-app -- helium --app=https://app.slack.com/client/";
    icon = "slacky";
    terminal = false;
    type = "Application";
    categories = [ "Network" "InstantMessaging" ];
  };

  xdg.desktopEntries.teams = {
    name = "Teams";
    exec = "uwsm-app -- helium --app=https://teams.cloud.microsoft/";
    icon = "teams";
    terminal = false;
    type = "Application";
    categories = [ "Network" "InstantMessaging" ];
  };

  xdg.desktopEntries.steam = {
    name = "Steam";
    comment = "Play games";
    exec = "/home/kevin/.config/nix-dotfiles/systems/deimos/bin/steam %U";
    icon = "steam";
    terminal = false;
    type = "Application";
    categories = [ "Game" ];
    settings = {
      TryExec = "/home/kevin/.config/nix-dotfiles/systems/deimos/bin/steam";
      StartupWMClass = "steam";
    };
  };
}
