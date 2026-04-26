{ pkgs, ... }:

let
  lib = pkgs.lib;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in
{

  home.packages = with pkgs; [
    fzf
    fd
    bat
  ];

  programs.direnv = {
    enable = false;
    nix-direnv.enable = false;
  };

  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      set fish_greeting # Disable greeting

      # Overwrite default ctrl+r history-pager
      fzf_configure_bindings
    '';

    shellInit = ''
      # Nix profile paths
      fish_add_path $HOME/.nix-profile/bin
      fish_add_path /etc/profiles/per-user/$USER/bin
      fish_add_path /run/current-system/sw/bin
      fish_add_path /nix/var/nix/profiles/default/bin

      # Host-local dotfiles scripts
      set -l dotfiles_host (hostname -s 2>/dev/null)
      if test -z "$dotfiles_host"
        set dotfiles_host (hostname)
      end

      set -l dotfiles_host_bin "$HOME/.config/nix-dotfiles/systems/$dotfiles_host/bin"
      if test -d "$dotfiles_host_bin"
        fish_add_path --prepend "$dotfiles_host_bin"
      end
    '' + lib.optionalString isDarwin ''

      # Homebrew config
      set -gx HOMEBREW_PREFIX "/opt/homebrew";
      set -gx HOMEBREW_CELLAR "/opt/homebrew/Cellar";
      set -gx HOMEBREW_REPOSITORY "/opt/homebrew";
      ! set -q PATH; and set PATH \'\'; set -gx PATH "/opt/homebrew/bin" "/opt/homebrew/sbin" $PATH;
      ! set -q MANPATH; and set MANPATH \'\'; set -gx MANPATH "/opt/homebrew/share/man" $MANPATH;
      ! set -q INFOPATH; and set INFOPATH \'\'; set -gx INFOPATH "/opt/homebrew/share/info" $INFOPATH;
    '' + ''

      # Krew
      fish_add_path $HOME/.krew/bin

      # Go Binaries
      fish_add_path $GOPATH/bin
    '' + lib.optionalString isDarwin ''

      # MySQL
      fish_add_path /opt/homebrew/opt/mysql-client/bin
    '' + ''

      # Cargo
      fish_add_path $HOME/.cargo/bin

      # Mise
      if command -q mise
        mise activate fish | source
      end
    '';

    plugins = [
      { name = "fzf"; src = pkgs.fishPlugins.fzf-fish.src; }
    ];

    functions = {
      c = ''
        set DIR (zoxide query -l | fzf)
        z $DIR
      '';
      t = ''
        tmux attach -t "$(tmux ls -F '#{session_name}:#{window_name}' | fzf)"
      '';
      awsx = ''
        if test -z $AWSX_PROFILES
            set -gx AWS_PROFILES (aws configure list-profiles | string split0)
        end

        set -gx AWS_PROFILE (echo $AWS_PROFILES | fzf)

        echo "Using profile: $AWS_PROFILE"
        aws sts get-caller-identity &> /dev/null
        if test $status != 0
            echo "AWS SSO Session expired. Logging in..."
            aws sso login
        else
            echo "Found valid SSO session, using it!"
        end
      '';
      ssm-headscale = ''
        set HEADSCALE_INSTANCE_ID (aws ec2 describe-instances --filters "Name=tag:Name,Values=headscale" --query 'Reservations[].Instances[].InstanceId' --output text)
        aws ssm start-session --document-name AWS-StartInteractiveCommand  --parameters command="bash -l" --target $HEADSCALE_INSTANCE_ID
      '';
    } // lib.optionalAttrs isDarwin {
      day = ''
        set -l vault "/Users/kevin/Library/Mobile Documents/iCloud~md~obsidian/Documents/Kevins Brain"
        set -l daily "$vault/Daily Notes"
        set -l year (env LC_TIME=C date "+%Y")
        set -l month (env LC_TIME=C date "+%b")
        set -l filename (env LC_TIME=C date "+%d.%m.%Y - %A").md
        set -l dir "$daily/$year/$month"
        set -l path "$dir/$filename"

        mkdir -p "$dir"
        if not test -f "$path"
            command cp "$vault/Extras/Templates/Daily Note - Template.md" "$path"
        end

        nvim "$path"
      '';
    };
  };

  programs.starship = {
    enable = true;

    settings = {
      aws.disabled = true;
      gcloud.disabled = true;
      git_status.disabled = true;
      command_timeout = 1500;
    };
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.eza = {
    enable = true;
    enableFishIntegration = true;
  };

  home.shellAliases = {
    "cat" = "bat -pp";
    "find" = "fd";
    "grep" = "rg";
    "k" = "kubectl";
    "ll" = "eza --icons --group --group-directories-first -l";
    "rebuild-system" = "~/.config/nix-dotfiles/scripts/rebuild-system.sh";
    "fish" = "/etc/profiles/per-user/kevin/bin/fish";
  };
}
