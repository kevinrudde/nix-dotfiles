local config_dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)")

if config_dir ~= nil then
  package.path = config_dir .. "?.lua;" .. config_dir .. "?/init.lua;" .. package.path
end

require("conf.env")
require("conf.input")
require("conf.looknfeel")
require("conf.rules")
require("conf.bindings")
require("conf.autostart")
require("hosts.deimos")
