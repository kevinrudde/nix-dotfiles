{ config
, pkgs
, lib
, flake
, ...
}:

let
  php = pkgs.php83.buildEnv {
    extensions = { enabled, all }: enabled ++ [ all.xdebug all.xsl ];
    extraConfig = ''
      memory_limit=512M
    '';
  };
in
{
  home.packages = with pkgs; [
    php
    php.packages.composer
    symfony-cli
  ];
}
