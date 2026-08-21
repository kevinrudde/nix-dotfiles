{ ... }:

let
  # Quickshell derives QML module names from the directory names below the shell
  # root: `bar/` becomes `qs.bar`, `widgets/` becomes `qs.widgets`. Linked
  # recursively rather than as one symlink to the store path, so those are real
  # directories holding individual symlinks.
  shellConfig = ./shell;
in
{
  xdg.configFile."quickshell/shell" = {
    source = shellConfig;
    recursive = true;
  };
}
