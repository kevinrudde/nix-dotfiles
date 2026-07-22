{ lib, ... }:
let
  extensionEntries = builtins.readDir ./extensions;
  extensionFiles = lib.filter (
    name: lib.hasSuffix ".ts" name && extensionEntries.${name} == "regular"
  ) (builtins.attrNames extensionEntries);
in
{
  # Pi owns runtime state (sessions, trust decisions, downloaded packages); keep
  # only the declarative settings and our extensions under Home Manager.
  home.file = (builtins.listToAttrs (map (name: {
    name = ".pi/agent/extensions/${name}";
    value.source = ./extensions + "/${name}";
  }) extensionFiles)) // {
    ".pi/agent/settings.json" = {
      source = ./settings.json;
      force = true;
    };
    ".pi/agent/AGENTS.md".source = ./AGENTS.md;
    ".pi/agent/APPEND_SYSTEM.md".source = ./APPEND_SYSTEM.md;
    ".pi/web-search.json".source = ./web-search.json;
  };
}
