{ pkgs, lib, ... }: {

  programs.ghostty = {
    enable = true;
    package =
      if pkgs.stdenv.hostPlatform.isDarwin
      then pkgs.ghostty-bin
      else null;

    systemd.enable = false;

    enableFishIntegration = true;

    settings = {
      font-family = "JetBrains Mono";
      font-size = 13;
      theme = "Kanagawa Wave";

      window-decoration = true;
      macos-titlebar-style = "hidden";
      focus-follows-mouse = true;
      confirm-close-surface = false;
      window-inherit-working-directory = false;
      working-directory = "home";

      keybind = [
        # Remap super to ctrl so macOS shortcuts work in the terminal
        "super+p=text:\\x10"
        "super+n=text:\\x0e"
        "super+u=text:\\x15"
        "super+l=text:\\x0c"
        "super+c=text:\\x03"
        # super+shift+c for actual copy (since super+c is remapped to ctrl+c above)
        "super+shift+c=copy_to_clipboard"
        "performable:ctrl+v=paste_from_clipboard"
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
