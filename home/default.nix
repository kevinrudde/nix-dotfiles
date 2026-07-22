{ pkgs
, inputs
, ...
}: {

  imports = [
    inputs.sops-nix.homeManagerModule
    inputs.catppuccin.homeModules.catppuccin
    ./features/shell
    ./features/packages
    ./features/mise
    ./features/git
    ./features/nvim
    ./features/secrets
    ./features/tmux
    ./features/wezterm
    ./features/ghostty
    ./features/go
    ./features/php
    ./features/k9s
    ./features/claude
    ./features/pi
  ];

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.05"; # Please read the comment before changing.

  # catppuccin/nix is switching `catppuccin.enable` into a global on/off toggle
  # and introducing `catppuccin.autoEnable` for auto-enrolling all ports. GTK/Qt
  # theming is configured manually (see home/deimos.nix), so keep auto-enroll off
  # to avoid clobbering it; ports are opted into explicitly (e.g. catppuccin.k9s).
  # Setting autoEnable explicitly also silences the migration warning.
  catppuccin = {
    enable = true;
    autoEnable = false;
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
