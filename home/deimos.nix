{ config, pkgs, lib, inputs, ... }:

let
  flavor = "mocha";
  accent = "sky";
  slackOpenLinksExternalExtensionId = "mcldoopdpdabagcpdmagjdbkbekgjihf";
  slackOpenLinksExternalHostName = "dev.kevin.slack_open_links_external";
  slackOpenLinksExternalExtensionPath = "${config.xdg.configHome}/helium/extensions/slack-open-links-external";
  slackOpenLinksExternalNativeHostPath = "${config.home.homeDirectory}/.local/bin/slack-open-link-external-native-host";
  slackOpenLinksExternalNativeHostManifest = {
    name = slackOpenLinksExternalHostName;
    description = "Open links clicked in the Slack web app with the system default browser.";
    path = slackOpenLinksExternalNativeHostPath;
    type = "stdio";
    allowed_origins = [
      "chrome-extension://${slackOpenLinksExternalExtensionId}/"
    ];
  };
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
    settings."*".AddKeysToAgent = "yes";
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

  xdg.configFile."helium/extensions/slack-open-links-external".source =
    ./deimos/helium/slack-open-links-external;

  xdg.configFile."net.imput.helium/NativeMessagingHosts/${slackOpenLinksExternalHostName}.json".text =
    builtins.toJSON slackOpenLinksExternalNativeHostManifest + "\n";

  home.file.".local/bin/slack-open-link-external-native-host" = {
    source = ./deimos/bin/slack-open-link-external-native-host;
    executable = true;
  };

  home.file.".local/bin/steam-deimos" = {
    source = ./deimos/bin/steam;
    executable = true;
  };

  xdg.desktopEntries.slack = {
    name = "Slack";
    exec = "uwsm-app -- helium --load-extension=${slackOpenLinksExternalExtensionPath} --app=https://app.slack.com/client/";
    icon = "slacky";
    terminal = false;
    type = "Application";
    categories = [ "Network" "InstantMessaging" ];
  };

  xdg.desktopEntries.spotify = {
    name = "Spotify";
    exec = "uwsm-app -- helium --app=https://open.spotify.com/";
    icon = "spotify";
    terminal = false;
    type = "Application";
    categories = [ "Music" ];
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
    exec = "${config.home.homeDirectory}/.local/bin/steam-deimos %U";
    icon = "steam";
    terminal = false;
    type = "Application";
    categories = [ "Game" ];
    settings = {
      TryExec = "${config.home.homeDirectory}/.local/bin/steam-deimos";
      StartupWMClass = "steam";
    };
  };
}
