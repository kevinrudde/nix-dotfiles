{ pkgs, lib, ... }: {

  programs.ghostty = {
    enable = true;
    # On macOS, install ghostty as a native app outside of nix
    package = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;

    enableFishIntegration = true;

    settings = {
      font-family = "JetBrainsMono Nerd Font Mono";
      font-size = if pkgs.stdenv.hostPlatform.isDarwin then 13 else 11;
      theme = "Kanagawa Wave";

      window-decoration = true;
      macos-titlebar-style = "hidden";
      focus-follows-mouse = true;
      confirm-close-surface = false;

      keybind = [
        # Remap super to ctrl so macOS shortcuts work in the terminal
        "super+p=text:\\x10"
        "super+n=text:\\x0e"
        "super+u=text:\\x15"
        "super+l=text:\\x0c"
        "super+c=text:\\x03"
        # super+shift+c for actual copy (since super+c is remapped to ctrl+c above)
        "super+shift+c=copy_to_clipboard"
        # Option+arrows for word navigation
        "alt+left=text:\\x1bb"
        "alt+right=text:\\x1bf"
        # super+arrows for line start/end
        "super+left=text:\\x01"
        "super+right=text:\\x05"
        "super+backspace=text:\\x15"
      ];
    };
  };
}
