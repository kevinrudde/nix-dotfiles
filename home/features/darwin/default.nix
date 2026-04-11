{ config
, pkgs
, lib
, ...
}:

{
  home.activation = {
    copyKeyBindings = lib.hm.dag.entryAfter ["writeBoundary"] ''
        run  cp -f ${./DefaultKeyBinding.dict} ~/Library/KeyBindings/DefaultKeyBinding.dict
    '';
  };
}
