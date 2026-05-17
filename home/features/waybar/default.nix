{ ... }:

{
  xdg.configFile = {
    "waybar/config".source = ./config;
    "waybar/style.css".source = ./style.css;
    "waybar/scripts/power-menu.sh" = {
      source = ./scripts/power-menu.sh;
      executable = true;
    };
    "waybar/scripts/power-usage.sh" = {
      source = ./scripts/power-usage.sh;
      executable = true;
    };
  };
}
