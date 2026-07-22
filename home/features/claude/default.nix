{ pkgs, lib, config, ... }:
let
  managed = ./settings.json;
in
{

  home.activation.claudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    claudeSettings="${config.home.homeDirectory}/.claude/settings.json"
    $DRY_RUN_CMD mkdir -p "$(dirname "$claudeSettings")"

    if [ -e "$claudeSettings" ]; then
      tmp="$(mktemp)"
      ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$claudeSettings" ${managed} > "$tmp"
      $DRY_RUN_CMD mv "$tmp" "$claudeSettings"
    else
      $DRY_RUN_CMD cp ${managed} "$claudeSettings"
    fi
    $DRY_RUN_CMD chmod 600 "$claudeSettings"
  '';
}
