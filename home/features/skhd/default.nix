{
  lib,
  ...
}: {

  home.file.".config/skhd/skhdrc" = {
    source = ./skhdrc;
  };

  home.activation = {
    initSkhd = lib.hm.dag.entryAfter ["writeBoundary"] ''
        run /opt/homebrew/bin/skhd --install-service
        run /opt/homebrew/bin/skhd --start-service
    '';
  };

}
