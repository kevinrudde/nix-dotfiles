{ pkgs, ... }:

let
  wallpaperRoot = "Pictures/Wallpapers";
  resolutions = [ "1920x1080" "1920x1200" "2560x1440" "3440x1440" ];

  setWallpapers = pkgs.writeShellApplication {
    name = "set-wallpapers";
    runtimeInputs = [ pkgs.jq pkgs.coreutils pkgs.findutils ];
    text = builtins.readFile ./set-wallpapers.sh;
  };
in
{
  home.packages = [ setWallpapers ];

  home.file = builtins.listToAttrs (map (resolution: {
    name = "${wallpaperRoot}/${resolution}/.keep";
    value.text = "";
  }) resolutions);

  xdg.configFile = {
    "hypr/hypridle.conf".source = ./hypridle.conf;
    "hypr/hyprlock.conf".source = ./hyprlock.conf;
    "hypr/xdph.conf".source = ./xdph.conf;
  };
}
