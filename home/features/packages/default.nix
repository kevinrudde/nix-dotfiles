{ pkgs, inputs, ... }:

let
  lib = pkgs.lib;
  system = pkgs.stdenv.hostPlatform.system;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in
{

  home.packages = with pkgs; [
    inputs.devenv.packages.${system}.devenv
    cachix
    nh

    nixpkgs-fmt
    sops
    nh

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
    ugrep
    bfs
    rtk
    natscli

    nodejs_24

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
  ] ++ lib.optionals isDarwin [
    _1password-cli
  ];
}
