local workspaces = require("conf.workspaces")

-- Desk monitors are matched on their EDID description, not on a connector.
-- The same screen shows up as DP-1 at one desk and DP-4 at the other -- which
-- port a cable lands in is not something either desk agrees on -- and a rule
-- written against the connector therefore applies at exactly one of them,
-- leaving the other desk on whatever Hyprland guesses. A description follows
-- the panel across ports, and a rule whose monitor is not attached is simply
-- inert, so every desk can be declared here at once.
--
-- The string after `desc:` is the `description` field of
-- `hyprctl monitors all -j`; a prefix of it is enough to match.
hl.monitor({
  output = "desc:ASUSTek COMPUTER INC XG27WQ L9LMAS000340",
  mode = "preferred",
  position = "0x0",
  scale = "auto",
})

-- Left of the ASUS, so a negative origin rather than an `auto-*` keyword:
-- auto placement resolves against whatever is already laid out when the rule
-- runs, which makes the row depend on rule order and on which cable came up
-- first. The ASUS anchors the desk at 0x0 and this one is 1920 logical pixels
-- wide at scale 1, so it starts exactly where the ASUS ends going left.
hl.monitor({
  output = "desc:AOC 2460G4 0x0001473B",
  mode = "preferred",
  position = "-1920x0",
  scale = "auto",
})

hl.monitor({
  output = "DP-1",
  mode = "3440x2560@60",
  position = "0x0",
  scale = "auto",
})

-- Workspaces 1-6 belong on the big screen in front of the keyboard, not on
-- whichever external happened to enumerate first.
workspaces.external_monitors = {
  "ASUSTek COMPUTER INC XG27WQ",
  "AOC 2460G4",
}

-- Kept in a local so conf.lid can replay the exact same rule when the lid
-- opens again; disabling a monitor is only undone by restating its rule.
local internal = {
  output = "eDP-1",
  mode = "1920x1200@60",
  position = "auto-right",
  scale = "1",
}

hl.monitor(internal)
require("conf.lid").setup(internal)

workspaces.configure_rules()
