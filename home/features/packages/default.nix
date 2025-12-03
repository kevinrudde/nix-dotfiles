{ pkgs, flake, ... }: {

  home.packages = with pkgs; [
    flake.inputs.devenv.packages.${system}.devenv
    cachix

    nixpkgs-fmt
    sops

    _1password-cli
    jq
    gnused
    ripgrep
    ast-grep
    unixtools.watch
    nmap
    htop
    coreutils
    pigz
    ssm-session-manager-plugin
    wget
    kubectl
    kubectx
    kubernetes-helm
    kubent
    stern
    uv
    cargo

    terraform

    nodejs_22

    act
    ory

    istioctl
    docker-client
    docker-buildx
    dive
    bun
    k9s
    gh
    k6
    awscli2

    kind
  ];
}

