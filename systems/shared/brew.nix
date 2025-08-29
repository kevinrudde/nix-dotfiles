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
    ];

    brews = [
      "docker-credential-helper"
      "argocd"
      "eks-node-viewer"
      "mysql-client"
      "television"
    ];

    casks = [
      "orbstack"
      "hammerspoon"
      "gitify"
      "boring-notch"
      "calibre"
    ];
  };
}
