-- Main modifier; hosts may override by setting the HL_MAIN_MOD global in
-- their hyprland.lua entrypoint before conf.bindings is required.
local main_mod = HL_MAIN_MOD or "ALT"

local workspaces = require("conf.workspaces")

local terminal = "ghostty +new-window"
-- Launcher command; hosts may override by setting the HL_LAUNCHER global in
-- their hyprland.lua entrypoint before conf.bindings is required.
local launcher = HL_LAUNCHER or "uwsm app -- fuzzel"
local browser = "zen-browser"
-- Locking goes through logind rather than straight to hyprlock, so this
-- keybind, the power menu and hypridle's idle/before-sleep locks all land on
-- one code path: hypridle's lock_cmd. Going through logind is also what sets
-- LockedHint, so anything else on the bus knows the session is locked.
local lock_cmd = "loginctl lock-session"
local resize_step = 50

hl.bind(main_mod .. " + SHIFT + M", hl.dsp.exec_cmd("hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))

hl.bind(main_mod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(main_mod .. " + D", hl.dsp.exec_cmd(launcher))
hl.bind(main_mod .. " + B", hl.dsp.exec_cmd("uwsm app -- " .. browser))
hl.bind(main_mod .. " + SHIFT + Q", hl.dsp.window.close())
hl.bind(main_mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(main_mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(main_mod .. " + P", hl.dsp.window.pseudo())

hl.bind(main_mod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(main_mod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(main_mod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(main_mod .. " + L", hl.dsp.focus({ direction = "right" }))

hl.bind(main_mod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(main_mod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(main_mod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(main_mod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))

hl.bind(main_mod .. " + R", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
  hl.bind("Left", hl.dsp.window.resize({ x = -resize_step, y = 0, relative = true }), {
    ignore_mods = true,
    repeating = true,
  })
  hl.bind("Right", hl.dsp.window.resize({ x = resize_step, y = 0, relative = true }), {
    ignore_mods = true,
    repeating = true,
  })
  hl.bind("R", hl.dsp.submap("reset"), {
    ignore_mods = true,
    release = true,
  })
  hl.bind("Escape", hl.dsp.submap("reset"))
end)

hl.bind(main_mod .. " + CTRL + J", hl.dsp.layout("preselect d"))
hl.bind(main_mod .. " + CTRL + K", hl.dsp.layout("preselect u"))
hl.bind(main_mod .. " + CTRL + H", hl.dsp.layout("preselect l"))
hl.bind(main_mod .. " + CTRL + L", hl.dsp.layout("preselect r"))
hl.bind(main_mod .. " + CTRL + SPACE", hl.dsp.layout("togglesplit"))
hl.bind(main_mod .. " + CTRL + SHIFT + SPACE", hl.dsp.layout("swapsplit"))

hl.bind("MOD5 + L", hl.dsp.exec_cmd(lock_cmd), {
  desc = "Lock screen",
})

hl.bind(main_mod .. " + F1", workspaces.focus(0))
hl.bind(main_mod .. " + SHIFT + F1", workspaces.move_window(0))

-- When the main modifier IS super, don't stack it twice.
local ws_switch_mod = (main_mod ~= "SUPER" and (main_mod .. " + ") or "") .. "SUPER + SHIFT + "
hl.bind(ws_switch_mod .. "Left", hl.dsp.focus({ workspace = "m-1" }))
hl.bind(ws_switch_mod .. "Right", hl.dsp.focus({ workspace = "m+1" }))

for workspace = 1, 6 do
  hl.bind(main_mod .. " + " .. workspace, workspaces.focus(workspace))
  hl.bind(main_mod .. " + SHIFT + " .. workspace, workspaces.move_window(workspace))
end

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("uwsm app -- wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), {
  locked = true,
  repeating = true,
})
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("uwsm app -- wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), {
  locked = true,
  repeating = true,
})
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("uwsm app -- wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), {
  locked = true,
  repeating = true,
})

-- The mic mute key has its own LED in the keycap on laptops that ship one (the
-- XPS 16 does, as platform::micmute off dell-laptop), and nothing drives it: the
-- kernel exposes the node but leaves the state to userspace, so the light stays
-- dark however the mic is set. Toggle the source and push the result to the LED
-- in one place, so the key, the light and PipeWire cannot disagree. The mute
-- state is read back from wpctl rather than assumed, since anything else may
-- have muted the source since the last press. A host without the LED node stops
-- after the toggle.
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd([[sh -c 'wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle; led=platform::micmute; [ -e "/sys/class/leds/$led" ] || exit 0; wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED && v=1 || v=0; brightnessctl -q --class=leds --device="$led" set "$v"']]), {
  locked = true,
})

hl.bind("XF86Launch5", hl.dsp.exec_cmd("uwsm app -- brightnessctl set 10%-"), {
  locked = true,
  repeating = true,
})
hl.bind("XF86Launch6", hl.dsp.exec_cmd("uwsm app -- brightnessctl set 10%+"), {
  locked = true,
  repeating = true,
})

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("uwsm app -- playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("uwsm app -- playerctl play-pause"), { locked = true })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("uwsm app -- playerctl stop"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("uwsm app -- playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("uwsm app -- playerctl previous"), { locked = true })

hl.bind(main_mod .. " + SHIFT + S", hl.dsp.exec_cmd([[sh -lc 'grim -g "$(slurp)" - | wl-copy']]))

hl.bind(main_mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })    -- main_mod + LMB: Move a window by dragging.
hl.bind(main_mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })  -- main_mod + RMB: Resize a window by dragging.
