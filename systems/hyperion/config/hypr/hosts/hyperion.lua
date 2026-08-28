local workspaces = require("conf.workspaces")

hl.monitor({
  output = "DP-1",
  mode = "3440x1440@60",
  position = "0x0",
  scale = "auto",
})

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
