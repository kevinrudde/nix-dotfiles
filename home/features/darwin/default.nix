{ config
, pkgs
, lib
, flake
, ...
}:

{
  targets.darwin.keybindings = {
    "\UF729" = "moveToBeginningOfParagraph:"; # home
    "\UF72B" = "moveToEndOfParagraph:"; # end
    "$\UF729" = "moveToBeginningOfParagraphAndModifySelection:"; # shift-home
    "$\UF72B" = "moveToEndOfParagraphAndModifySelection:"; # shift-end
    "^\UF729" = "moveToBeginningOfDocument:"; # ctrl-home
    "^\UF72B" = "moveToEndOfDocument:"; # ctrl-end
    "^$\UF729" = "moveToBeginningOfDocumentAndModifySelection:"; # ctrl-shift-home
    "^$\UF72B" = "moveToEndOfDocumentAndModifySelection:"; # ctrl-shift-end
    "^\UF702" = "moveWordLeft:"; # ctrl-left
    "^$\UF702" = "moveWordLeftAndModifySelection:"; # ctrl-shift-left
    "^\UF703" = "moveWordRight:"; # ctrl-right
    "^$\UF703" = "moveWordRightAndModifySelection:"; # ctrl-shift-right
    "@\UF702" = "moveWordLeft:"; # cmd-left
    "@$\UF702" = "moveWordLeftAndModifySelection:"; # cmd-shift-left
    "@\UF703" = "moveWordRight:"; # cmd-right
    "@$\UF703" = "moveWordRightAndModifySelection:"; # cmd-shift-right
  };
}
