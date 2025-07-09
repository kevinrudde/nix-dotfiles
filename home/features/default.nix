{ ... }: {
  imports = [
    ./packages.nix
    ./shell
    ./git
    ./ssh
    ./editors
    ./secrets
    ./terminals
    ./development
    ./ai
    ./darwin
    ./linux
  ];
} 