local main_mod = "ALT"

local workspaces = require("conf.workspaces")

local terminal = "ghostty"
local launcher = "fuzzel"
local browser = "zen-browser"
local lock_cmd = "uwsm app -- hyprlock --immediate-render"
local resize_step = 50

hl.bind(main_mod .. " + SHIFT + M", hl.dsp.exec_cmd("hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))

hl.bind(main_mod .. " + Return", hl.dsp.exec_cmd("uwsm app -- " .. terminal))
hl.bind(main_mod .. " + D", hl.dsp.exec_cmd("uwsm app -- " .. launcher))
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
hl.bind(main_mod .. " + SUPER + Left", hl.dsp.focus({ workspace = "m-1" }))
hl.bind(main_mod .. " + SUPER + Right", hl.dsp.focus({ workspace = "m+1" }))

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

hl.bind("ALT + mouse:272", hl.dsp.window.drag(), { mouse = true })    -- ALT + LMB: Move a window by dragging more than 10px.
hl.bind("ALT + mouse:272", hl.dsp.window.resize(), { mouse = true })  -- ALT + LMB: Floats a window by clicking
