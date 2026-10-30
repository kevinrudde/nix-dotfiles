local workspaces = require("conf.workspaces")

-- Matched on EDID description rather than connector; see hosts/hyperion.lua
-- for why. The string after `desc:` is a prefix of the `description` field of
-- `hyprctl monitors all -j`.
hl.monitor({
  output = "desc:ASUSTek COMPUTER INC XG27WQ L9LMAS000340",
  mode = "preferred",
  position = "0x0",
  scale = "auto",
})

-- Left of the ASUS: it anchors the desk at 0x0 and this one is 1920 logical
-- pixels wide at scale 1.
hl.monitor({
  output = "desc:AOC 2460G4 0x0001473B",
  mode = "preferred",
  position = "-1920x0",
  scale = "auto",
})

-- Anything else that gets plugged in lands to the right.
hl.monitor({
  output = "",
  mode = "preferred",
  position = "auto-right",
  scale = "auto",
})

-- Workspaces 1-6 on the ASUS in front of the keyboard, 7 on the AOC.
workspaces.external_monitors = {
  "ASUSTek COMPUTER INC XG27WQ",
  "AOC 2460G4",
}

workspaces.configure_rules()
