{ ... }: {
  imports = [
    ./packages.nix
    ./shell
    ./git
    ./editors
    ./secrets
    ./terminals
    ./development
    ./darwin
    ./linux
  ];
} 