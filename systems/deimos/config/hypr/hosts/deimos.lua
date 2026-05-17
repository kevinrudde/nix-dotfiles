local workspaces = require("conf.workspaces")

hl.monitor({
  output = "DP-1",
  mode = "preferred",
  position = "0x0",
  scale = "auto",
})

hl.monitor({
  output = "eDP-1",
  mode = "preferred",
  position = "auto-right",
  scale = "auto",
})

workspaces.configure_rules()
