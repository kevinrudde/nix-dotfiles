{ pkgs, config, ... }: {

  home.packages = with pkgs; lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
    wezterm
  ];

  home.file = {
    ".config/wezterm/wezterm.lua".text = let
      font_size = if pkgs.stdenv.hostPlatform.isDarwin then "13.0" else "11.0";
    in builtins.replaceStrings ["@font_size@"] [font_size] (builtins.readFile ./wezterm.lua);
  };
}
