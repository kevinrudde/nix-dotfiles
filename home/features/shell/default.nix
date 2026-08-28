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

      # Mise: use Home Manager's profile package rather than a separately
      # installed copy in ~/.local/bin.
      if test -x $HOME/.nix-profile/bin/mise
        $HOME/.nix-profile/bin/mise activate fish | source
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
        # Cache the profile list for this shell only (not exported: child
        # processes have no use for it).
        if not set -q AWSX_PROFILES
            set -g AWSX_PROFILES (aws configure list-profiles)
        end

        set -l selected (printf '%s\n' $AWSX_PROFILES | fzf --prompt "aws profile> ")
        if test -z "$selected"
            echo "No profile selected, keeping $AWS_PROFILE"
            return 1
        end

        # -g: current shell session only. Other shells and future sessions are
        # untouched, and nothing is written to universal variables.
        set -gx AWS_PROFILE $selected

        echo "Using profile: $AWS_PROFILE"
        aws sts get-caller-identity &> /dev/null
        if test $status != 0
            echo "AWS SSO Session expired. Logging in..."
            if not aws sso login
                echo "SSO login failed - kubectl and k9s stay locked."
                return 1
            end
        else
            echo "Found valid SSO session, using it!"
        end

        set -gx AWSX_SESSION_ACTIVE 1
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
      aws = {
        disabled = false;
        # Without this starship hides the module unless static credentials are
        # present; with SSO there are none, so gate on AWS_PROFILE instead.
        force_display = true;
        symbol = "☁️";
        format = "[$symbol $profile]($style) ";
        style = "bold yellow";
      };
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
  };
}
