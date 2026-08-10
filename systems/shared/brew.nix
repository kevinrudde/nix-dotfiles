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
      "luarocks"
    ];

    casks = [
      "orbstack"
      "hammerspoon"
      "calibre"
      "codex"
      "dbeaver-community"
      "t3-code"
    ];
  };
}
