-- Entry point for Hyprland's embedded Lua config.
-- The companion default.nix builds a directory that places this file next to
-- the other module files and a host.lua stub, so require() resolves locally.

local function script_dir()
    local source = debug.getinfo(1, "S").source
    if source:sub(1, 1) == "@" then
        source = source:sub(2)
    end
    return source:match("(.*/)") or "./"
end

package.path = script_dir() .. "?.lua;" .. package.path

require("host")
require("input")
require("visual")
require("rules")
require("binds")
require("autostart")
