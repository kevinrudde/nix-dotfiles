{ pkgs, lib, ... }:
lib.mkIf pkgs.stdenv.isLinux {
  programs.fish = {
    # Linux-specific shell initialization
    shellInit = ''
      # Flatpak applications
      fish_add_path $HOME/.local/share/flatpak/exports/bin
      fish_add_path /var/lib/flatpak/exports/bin
      
      # Local binaries (user-installed)
      fish_add_path $HOME/.local/bin
      
      # AppImage applications (if using AppImageLauncher)
      if test -d $HOME/Applications
        fish_add_path $HOME/Applications
      end
      
      # Distribution-specific paths could go here
      # Example: Arch User Repository (AUR) helper paths
      # Example: Python user packages: $HOME/.local/lib/python*/site-packages
    '';
  };
} 