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
    ];

    brews = [
      "docker-credential-helper"
      "argocd"
      "mysql-client"
      "television"
    ];

    casks = [
      "orbstack"
      "hammerspoon"
      "gitify"
    ];
  };
}
