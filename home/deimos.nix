{ config, pkgs, lib, inputs, ... }:

let
  flavor = "mocha";
  accent = "sky";
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
  qtColorName = "catppuccin-${flavor}-${accent}";
  qtctConfig = colorSchemePath: ''
    [Appearance]
    color_scheme_path=${colorSchemePath}
    custom_palette=true
    icon_theme=${iconTheme.name}
    standard_dialogs=default
    style=kvantum

    [Fonts]
    fixed="JetBrains Mono,10,-1,5,50,0,0,0,0,0"
    general="JetBrains Mono,10,-1,5,50,0,0,0,0,0"

    [Interface]
    activate_item_on_single_click=1
    buttonbox_layout=0
    cursor_flash_time=1000
    dialog_buttons_have_icons=1
    double_click_interval=400
    gui_effects=@Invalid()
    keyboard_scheme=2
    menus_have_icons=true
    show_shortcuts_in_context_menus=true
    stylesheets=@Invalid()
    toolbutton_style=4
    underline_shortcut=1
    wheel_scroll_lines=3
  '';
in
{
  imports = [
    ./default.nix
    ./features/hypr
    ./features/quickshell
    ./features/librepods
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

  gtk = {
    enable = true;
    theme = gtkTheme;
    iconTheme = iconTheme;
    colorScheme = "dark";

    gtk4 = {
      theme = gtkTheme;
      iconTheme = iconTheme;
      colorScheme = null;
      extraConfig."gtk-interface-color-scheme" = "prefer-dark";
    };
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

  qt = {
    enable = true;
    platformTheme.name = "qt6ct";
    style.name = "kvantum";

    kvantum = {
      enable = true;
      themes = [
        (pkgs.catppuccin-kvantum.override {
          variant = flavor;
          inherit accent;
        })
      ];
      settings.General.theme = qtColorName;
    };
  };

  xdg.configFile."qt5ct/qt5ct.conf" = {
    text = qtctConfig "${pkgs.catppuccin-qt5ct}/share/qt5ct/colors/${qtColorName}.conf";
    force = true;
  };

  xdg.configFile."qt6ct/qt6ct.conf" = {
    text = qtctConfig "${pkgs.catppuccin-qt5ct}/share/qt6ct/colors/${qtColorName}.conf";
    force = true;
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
