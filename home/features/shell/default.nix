{ pkgs, ... }: {

  home.packages = with pkgs; [
    fzf
    fd
    bat
    lazygit
    delta
    bottom
    duf
    dust
    just
    watchexec
    hyperfine
    tree
    tldr
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.fish = {
    enable = true;

    # Custom abbreviations for productivity
    shellAbbrs = {
      # 🐳 Docker & Containers
      "d" = "docker";
      "dc" = "docker-compose";
      "dps" = "docker ps";
      "di" = "docker images";
      "dcup" = "docker-compose up -d";
      "dcdown" = "docker-compose down";
      
      # ☸️ Kubernetes  
      "kc" = "kubectl";
      "kgp" = "kubectl get pods";
      "kgs" = "kubectl get services";
      "kgd" = "kubectl get deployments";
      "kdp" = "kubectl describe pod";
      "kl" = "kubectl logs";
      
      # 📁 File operations
      "la" = "eza -la --icons";
      "lt" = "eza --tree --icons";
      "lz" = "eza -la --icons | head -20";
      
      # 🔍 Search & Find
      "rg" = "rg --color=always";
      "fd" = "fd --color=always";
      "bat" = "bat --style=numbers,changes";
      
      # 📦 Package Management
      "nr" = "nix-rebuild";
      "ns" = "nix search nixpkgs";
      "nsh" = "nix-shell";
      "nb" = "nix build";
      
      # 🚀 Development
      "vim" = "nvim";
      "v" = "nvim";
      "lg" = "lazygit";
      "t" = "tmux";
      "ta" = "tmux attach";
      "tn" = "tmux new-session";
      
      # 🌐 Network & System
      "ping" = "ping -c 4";
      "ports" = "netstat -tuln";
      "myip" = "curl -s ifconfig.me";
      "speed" = "speedtest-cli";
      
      # 📊 System monitoring
      "btm" = "btm --color always";
      "htop" = "btm";
      "df" = "duf";
      "du" = "dust";
      "ps" = "procs";
    };

    interactiveShellInit = ''
      set fish_greeting # Disable greeting

      # Overwrite default ctrl+r history-pager
      fzf_configure_bindings
      
      # Configure fish-abbreviation-tips plugin
      set -U ABBR_TIPS_PROMPT "\n💡 \e[1;36m{{ .abbr }}\e[0m \e[2m=>\e[0m \e[32m{{ .cmd }}\e[0m"
      set -U ABBR_TIPS_REGEXES \
        '(^(\w+\s+)+(-{1,2})\w+)(\s\S+)' \
        '(^( ?\w+){3}).*' \
        '(^( ?\w+){2}).*' \
        '(^( ?\w+){1}).*'
    '';

    # workaround for fixing the path order: https://github.com/LnL7/nix-darwin/issues/122
    shellInit = ''
      # Homebrew config
      set -gx HOMEBREW_PREFIX "/opt/homebrew";
      set -gx HOMEBREW_CELLAR "/opt/homebrew/Cellar";
      set -gx HOMEBREW_REPOSITORY "/opt/homebrew";
      ! set -q PATH; and set PATH \'\'; set -gx PATH "/opt/homebrew/bin" "/opt/homebrew/sbin" $PATH;
      ! set -q MANPATH; and set MANPATH \'\'; set -gx MANPATH "/opt/homebrew/share/man" $MANPATH;
      ! set -q INFOPATH; and set INFOPATH \'\'; set -gx INFOPATH "/opt/homebrew/share/info" $INFOPATH;

      # Volta
      set -gx VOLTA_HOME $HOME/.volta
      fish_add_path $VOLTA_HOME/bin

      # Go Binaries
      fish_add_path $GOPATH/bin

      # MySQL
      fish_add_path /opt/homebrew/opt/mysql-client/bin

      # Cargo
      fish_add_path $HOME/.cargo/bin
    '';

    plugins = [
      # 🔍 Enhanced fuzzy finding and file navigation
      { name = "fzf"; src = pkgs.fishPlugins.fzf-fish.src; }
      
      # 🧠 Auto-completion and productivity
      { name = "autopair"; src = pkgs.fishPlugins.autopair.src; }        # Auto-close parentheses, quotes, etc.
      { name = "sponge"; src = pkgs.fishPlugins.sponge.src; }            # Remove failed commands from history
      
      # 🎨 Better command output and experience  
      { name = "colored-man-pages"; src = pkgs.fishPlugins.colored-man-pages.src; } # Colorized man pages
      
      # 🔧 Git workflow enhancement
      { name = "forgit"; src = pkgs.fishPlugins.forgit.src; }            # Interactive git commands using fzf
      { name = "plugin-git"; src = pkgs.fishPlugins.plugin-git.src; }    # Git aliases and functions
      
      # 🚀 Shell environment and compatibility
      { name = "bass"; src = pkgs.fishPlugins.bass.src; }                # Run bash utilities in fish shell
      { name = "foreign-env"; src = pkgs.fishPlugins.foreign-env.src; }  # Source bash scripts in fish
      
      # 💡 Smart command suggestions
      { name = "pisces"; src = pkgs.fishPlugins.pisces.src; }            # Auto-matching quotes, brackets, etc.
      
      # 🧠 Learning and productivity aids
      { 
        name = "fish-abbreviation-tips"; 
        src = pkgs.fetchFromGitHub {
          owner = "Gazorby";
          repo = "fish-abbreviation-tips";
          rev = "v0.7.0";
          sha256 = "sha256-F1t81VliD+v6WEWqj1c1ehFBXzqLyumx5vV46s/FZRU=";
        };
      }
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
      
      # 🔍 Find unmerged remote branches by author
      gunmerged = ''
        # Default to current git user if no argument provided
        set author_filter $argv[1]
        if test -z "$author_filter"
            set author_filter (git config user.name)
        end
        
        echo "🔍 Searching for unmerged branches by: $author_filter"
        
        for b in (git branch -r --no-merged | grep 'origin/' | string trim)
            set info (git log -1 --pretty=format:'%ci | %an' $b)
            echo "$info | $b"
        end | grep -i "$author_filter" | sort -t '|' -k2,2 -k1,1r
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
    "tailscale" = "/Applications/Tailscale.localized/Tailscale.app/Contents/MacOS/Tailscale";
    "k" = "kubectl";
    "ll" = "eza --icons --group --group-directories-first -l";
    # New CLI tool shortcuts
    "tree" = "broot --height 20";               # Interactive directory navigator
    "json" = "jless";                           # Interactive JSON viewer
    "cut" = "choose";                           # Human-friendly cut replacement
    "dig" = "dog";                              # Modern DNS lookup (dogdns)
    "curl" = "httpie --print=HhBb";             # Modern HTTP client
  };
}
