local config_dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
local shared_dir = config_dir .. "../../../shared/hypr/"

if config_dir ~= nil then
  package.path = config_dir .. "?.lua;" .. config_dir .. "?/init.lua;"
    .. shared_dir .. "?.lua;" .. shared_dir .. "?/init.lua;" .. package.path
end

-- Windows key as the main modifier for this host (see conf.bindings).
HL_MAIN_MOD = "SUPER"

-- This host runs vicinae (home/features/vicinae) instead of the shared
-- default of fuzzel. `toggle` is a one-shot IPC call into the user-service
-- daemon, so it does not get a uwsm app scope of its own.
HL_LAUNCHER = "vicinae toggle"

require("conf.env")
require("conf.input")
require("conf.looknfeel")
require("conf.rules")
require("conf.bindings")
require("conf.autostart")
require("hosts.hyperion")
