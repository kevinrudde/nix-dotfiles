{ config
, pkgs
, lib
, flake
, ...
}:

{
  imports = [
    ./hammerspoon
  ];

  home.activation = {
    copyKeyBindings = lib.hm.dag.entryAfter ["writeBoundary"] ''
        run  cp -f ${./DefaultKeyBinding.dict} ~/Library/KeyBindings/DefaultKeyBinding.dict
    '';
  };
}