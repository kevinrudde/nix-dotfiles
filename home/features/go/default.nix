{ pkgs, config, ... }: {

  programs.go = {
    enable = true;
    package = pkgs.go_1_24;
    env.GOPATH = "${
    if pkgs.stdenv.hostPlatform.isDarwin
    then "/Users/kevin/.go"
    else "/home/kevin/.go"
    }";
  };
}
