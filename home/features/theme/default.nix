{ pkgs, lib, ... }:

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

  # qt.enable makes HM inject the nix store's Qt plugin dirs into
  # systemd.user.sessionVariables (-> environment.d -> every app in the
  # uwsm session). Distro-built Qt apps (quickshell from pacman) then load
  # plugins built against a different Qt and crash at startup. Blank them:
  # apps find plugins relative to their own Qt libraries, so nothing loses
  # out.
  systemd.user.sessionVariables.QT_PLUGIN_PATH = lib.mkForce "";
  systemd.user.sessionVariables.QML2_IMPORT_PATH = lib.mkForce "";

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
}
