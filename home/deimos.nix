{ config, pkgs, lib, inputs, ... }:

let
  slackOpenLinksExternalExtensionId = "mcldoopdpdabagcpdmagjdbkbekgjihf";
  slackOpenLinksExternalHostName = "dev.kevin.slack_open_links_external";
  slackOpenLinksExternalExtensionPath = "${config.xdg.configHome}/helium/extensions/slack-open-links-external";
  slackOpenLinksExternalNativeHostPath = "${config.home.homeDirectory}/.local/bin/slack-open-link-external-native-host";
  widevinePath = "/var/lib/widevine/WidevineCdm";
  spotifyChromiumProfilePath = "${config.xdg.configHome}/chromium-spotify";
  slackOpenLinksExternalNativeHostManifest = {
    name = slackOpenLinksExternalHostName;
    description = "Open links clicked in the Slack web app with the system default browser.";
    path = slackOpenLinksExternalNativeHostPath;
    type = "stdio";
    allowed_origins = [
      "chrome-extension://${slackOpenLinksExternalExtensionId}/"
    ];
  };
in
{
  imports = [
    ./default.nix
    ./features/hypr
    ./features/quickshell
    ./features/theme
    # ./features/librepods
  ];

  home.username = "kevin";
  home.homeDirectory = "/home/kevin";

  nixpkgs.config.allowUnfree = true;

  targets.genericLinux.enable = true;

  programs.ghostty.settings = {
    mouse-scroll-multiplier = "precision:0.1,discrete:1";
    quit-after-last-window-closed = true;
    quit-after-last-window-closed-delay = "5m";
  };

  xdg.configFile."wireplumber/wireplumber.conf.d/51-bluez-avrcp.conf".text = ''
    monitor.bluez.properties = {
      bluez5.dummy-avrcp-player = true
    }

    monitor.bluez.rules = [
      {
        matches = [
          {
            node.name = "~bluez_output.*"
            media.class = "Audio/Sink"
          }
        ]
        actions = {
          update-props = {
            # Beat WirePlumber's +30000 boost for the previously configured sink.
            priority.session = 40000
          }
        }
      }
      {
        matches = [
          {
            device.api = "bluez5"
          }
        ]
        actions = {
          update-props = {
            session.dont-restore-off-profile = true
          }
        }
      }
    ]

    device.profile.priority.rules = [
      {
        matches = [
          {
            device.name = "bluez_card.74_15_F5_21_E1_26"
          }
        ]
        actions = {
          update-props = {
            priorities = [
              "a2dp-sink-sbc_xq"
              "a2dp-sink"
              "a2dp-sink-sbc"
            ]
          }
        }
      }
    ]
  '';

  xdg.configFile."helium/extensions/slack-open-links-external".source =
    ./deimos/helium/slack-open-links-external;

  xdg.configFile."net.imput.helium/NativeMessagingHosts/${slackOpenLinksExternalHostName}.json".text =
    builtins.toJSON slackOpenLinksExternalNativeHostManifest + "\n";

  xdg.configFile."chromium-spotify/WidevineCdm/latest-component-updated-widevine-cdm" = {
    text = builtins.toJSON { Path = widevinePath; } + "\n";
    force = true;
  };

  home.file.".local/bin/slack-open-link-external-native-host" = {
    source = ./deimos/bin/slack-open-link-external-native-host;
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
    exec = "uwsm-app -- chromium-browser --user-data-dir=${spotifyChromiumProfilePath} --app=https://open.spotify.com/";
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
    exec = "/usr/bin/muvm ${config.home.homeDirectory}/.local/share/Steam/steamrtarm64/steam %U";
    icon = "steam";
    terminal = false;
    type = "Application";
    categories = [ "Game" ];
    settings = {
      TryExec = "/usr/bin/muvm";
      StartupWMClass = "steam";
    };
  };
}
