local config_dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
local shared_dir = config_dir .. "../../../shared/hypr/"

if config_dir ~= nil then
  package.path = config_dir .. "?.lua;" .. config_dir .. "?/init.lua;"
    .. shared_dir .. "?.lua;" .. shared_dir .. "?/init.lua;" .. package.path
end

-- Windows key as the main modifier for this host (see conf.bindings).
HL_MAIN_MOD = "SUPER"

require("conf.env")
require("conf.input")
require("conf.looknfeel")
require("conf.rules")
require("conf.bindings")
require("conf.autostart")
require("hosts.hyperion")
