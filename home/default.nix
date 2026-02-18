{ pkgs
, flake
, ...
}: {

  imports = [
    flake.inputs.sops-nix.homeManagerModule
    flake.inputs.catppuccin.homeModules.catppuccin
    ./features/shell
    ./features/packages
    ./features/git
    ./features/nvim
    ./features/secrets
    ./features/tmux
    ./features/wezterm
    ./features/go
    ./features/php
    ./features/k9s
  ];

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.05"; # Please read the comment before changing.

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
