{ ... }: {
  imports = [
    ./packages.nix
    ./shell
    ./git
    ./editors
    ./secrets
    ./terminals
    ./development
    ./ai
    ./darwin
    ./linux
  ];
} 