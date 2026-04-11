{ pkgs, inputs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
in
{

  home.packages = with pkgs; [
    inputs.devenv.packages.${system}.devenv
    cachix

    nixpkgs-fmt
    sops
    nh

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
    btop

    nodejs_22

    act
    ory

    istioctl
    docker-client
    docker-buildx
    dive
    bun
    gh
    k6
    awscli2

    kind
  ];
}
