{ pkgs
, ...
}: {

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };

    taps = [
      "aws/tap"
      "TheBoredTeam/boring-notch"
      "jackielii/tap"
    ];

    brews = [
      "docker-credential-helper"
      "argocd"
      "eks-node-viewer"
      "mysql-client"
      "television"
      "aqua"
      "mise"
      "nss"
      "opencode"
      "skhd-zig"
      "llama.cpp"
    ];

    casks = [
      "orbstack"
      "hammerspoon"
      "gitify"
      "boring-notch"
      "calibre"
      "codex"
      "beekeeper-studio"
    ];
  };
}
