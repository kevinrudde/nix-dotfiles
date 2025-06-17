{ pkgs, config, ... }: {

  home.packages = with pkgs; [
    wezterm
  ];

  home.file = {
    ".config/wezterm/wezterm.lua".source = ./wezterm.lua;
  };
}