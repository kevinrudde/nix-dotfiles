-- Placeholder until the monitors are known: take whatever is attached at its
-- preferred mode. Replace with `desc:` rules from `hyprctl monitors all -j`
-- once the machine is installed (see hosts/hyperion.lua for the pattern).
hl.monitor({
  output = "",
  mode = "preferred",
  position = "auto",
  scale = "auto",
})

require("conf.workspaces").configure_rules()
