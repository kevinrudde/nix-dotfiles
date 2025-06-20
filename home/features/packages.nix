{ pkgs, flake, ... }: {

  home.packages = with pkgs; [
    # ═══════════════════════════════════════════════════════════════════════════
    # 📦 DEVELOPMENT ENVIRONMENT & PACKAGE MANAGERS
    # ═══════════════════════════════════════════════════════════════════════════
    flake.inputs.devenv.packages.${system}.devenv
    cachix
    nixpkgs-fmt
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 🔐 SECURITY & SECRETS MANAGEMENT
    # ═══════════════════════════════════════════════════════════════════════════
    sops
    _1password-cli
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 🛠️ SYSTEM UTILITIES & CLI TOOLS
    # ═══════════════════════════════════════════════════════════════════════════
    jq
    jless                    # Interactive JSON viewer/explorer
    gnused
    ripgrep
    choose                   # Human-friendly cut/awk alternative
    unixtools.watch
    entr                     # File watcher for automatic command execution
    htop
    ncdu
    broot                    # Interactive directory tree navigator
    lsof
    coreutils
    pigz
    wget
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 🌐 NETWORK & MONITORING TOOLS
    # ═══════════════════════════════════════════════════════════════════════════
    nmap
    bandwhich
    dogdns                   # Modern dig replacement for DNS queries
    httpie                   # User-friendly HTTP client (modern curl)
    tailscale
    
    # ═══════════════════════════════════════════════════════════════════════════
    # ☁️ CLOUD & INFRASTRUCTURE TOOLS
    # ═══════════════════════════════════════════════════════════════════════════
    kubectl
    kubectx
    kubernetes-helm
    kubent
    stern
    k9s
    istioctl
    kind
    awscli2
    ssm-session-manager-plugin
    terraform
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 🐳 CONTAINER & DOCKER TOOLS
    # ═══════════════════════════════════════════════════════════════════════════
    docker-client
    docker-buildx
    dive
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 💻 DEVELOPMENT LANGUAGES & RUNTIMES
    # ═══════════════════════════════════════════════════════════════════════════
    nodejs_22
    cargo
    uv
    bun
    mise
    asdf-vm
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 🔧 DEVELOPMENT TOOLS & VERSION CONTROL
    # ═══════════════════════════════════════════════════════════════════════════
    gh
    gh-dash                  # GitHub dashboard in terminal
    act
    just
    watchexec
    hyperfine
    tldr
    procs
    sd
    glow
    slides                   # Terminal-based presentations
    tokei
    mkcert
    commitizen               # Interactive commit message builder
    ast-grep                 # Structural code search and rewriting
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 🧪 TESTING & QUALITY ASSURANCE
    # ═══════════════════════════════════════════════════════════════════════════
    k6
    shellcheck
    shfmt
    yamllint
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 🏢 ENTERPRISE & IDENTITY TOOLS
    # ═══════════════════════════════════════════════════════════════════════════
    ory
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 📊 DATA & ANALYTICS
    # ═══════════════════════════════════════════════════════════════════════════
    # Add data processing tools here
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 🎨 MULTIMEDIA & CONTENT
    # ═══════════════════════════════════════════════════════════════════════════
    # Add multimedia tools here
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 📱 MOBILE DEVELOPMENT
    # ═══════════════════════════════════════════════════════════════════════════
    # Add mobile dev tools here
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 🌍 WEB DEVELOPMENT
    # ═══════════════════════════════════════════════════════════════════════════
    # Add web-specific tools here
  ];
}

