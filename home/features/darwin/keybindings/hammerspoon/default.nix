{
  lib,
  ...
}: {

  home.file.".hammerspoon" = {
    source = ./config;
    recursive = true;
  };

  home.activation = {
    reloadHammerspoon = lib.hm.dag.entryAfter ["writeBoundary"] ''
        run  /opt/homebrew/bin/hs -c "hs.reload()"
    '';
  };

}
