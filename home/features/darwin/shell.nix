 { pkgs, lib, ... }:
lib.mkIf pkgs.stdenv.isDarwin {
  programs.fish = {
    # macOS-specific shell initialization for Homebrew integration
    # This addresses the nix-darwin path ordering issue: https://github.com/LnL7/nix-darwin/issues/122
    shellInit = ''
      # Homebrew environment configuration (macOS only)
      set -gx HOMEBREW_PREFIX "/opt/homebrew";
      set -gx HOMEBREW_CELLAR "/opt/homebrew/Cellar";
      set -gx HOMEBREW_REPOSITORY "/opt/homebrew";
      ! set -q PATH; and set PATH \'\'; set -gx PATH "/opt/homebrew/bin" "/opt/homebrew/sbin" $PATH;
      ! set -q MANPATH; and set MANPATH \'\'; set -gx MANPATH "/opt/homebrew/share/man" $MANPATH;
      ! set -q INFOPATH; and set INFOPATH \'\'; set -gx INFOPATH "/opt/homebrew/share/info" $INFOPATH;

      # Homebrew package-specific paths
      fish_add_path /opt/homebrew/opt/mysql-client/bin
    '';
  };
} 