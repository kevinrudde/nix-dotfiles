{ pkgs
, remapKeys
, ...
}: {
  fonts = {
    packages = [
      pkgs.nerd-fonts.jetbrains-mono
    ];
  };
}
