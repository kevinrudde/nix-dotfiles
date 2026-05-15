local mod = "ALT"

-- Launchers
hl.bind(mod .. " + Return", hl.dsp.exec_cmd("uwsm app -- kitty"))
hl.bind(mod .. " + Space",  hl.dsp.exec_cmd("uwsm app -- fuzzel"))
hl.bind(mod .. " + B",      hl.dsp.exec_cmd("uwsm app -- zen-browser --new-window"))

-- Window management
hl.bind(mod .. " + SHIFT + Q",     hl.dsp.window.close())
hl.bind(mod .. " + F",             hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + SHIFT + Space", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + P",             hl.dsp.window.pseudo())

-- Focus
hl.bind(mod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + L", hl.dsp.focus({ direction = "right" }))

-- Move window
hl.bind(mod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(mod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))

-- Cross-monitor moves
hl.bind(mod .. " + SHIFT + SUPER + right", hl.dsp.window.move({ monitor = "+1" }))
hl.bind(mod .. " + SHIFT + SUPER + left",  hl.dsp.window.move({ monitor = "-1" }))

-- Workspaces 1-6 plus the scratchpad (F1 → 0)
hl.bind(mod .. " + F1",         hl.dsp.focus({ workspace = 0 }))
hl.bind(mod .. " + SHIFT + F1", hl.dsp.window.move({ workspace = 0 }))
for i = 1, 6 do
    hl.bind(mod .. " + " .. i,         hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mod .. " + SHIFT + P", hl.dsp.focus({ workspace = "-1" }))
hl.bind(mod .. " + SHIFT + N", hl.dsp.focus({ workspace = "+1" }))

-- Submaps
hl.bind(mod .. " + R",             hl.dsp.submap("resize"))
hl.bind(mod .. " + SHIFT + comma", hl.dsp.submap("layout"))

hl.define_submap("resize", function()
    hl.bind("right", hl.dsp.window.resize({ x = 50,  y = 0,   relative = true }), { repeating = true })
    hl.bind("left",  hl.dsp.window.resize({ x = -50, y = 0,   relative = true }), { repeating = true })
    hl.bind("up",    hl.dsp.window.resize({ x = 0,   y = -50, relative = true }), { repeating = true })
    hl.bind("down",  hl.dsp.window.resize({ x = 0,   y = 50,  relative = true }), { repeating = true })
    hl.bind("Return", hl.dsp.submap("reset"))
    hl.bind("Escape", hl.dsp.submap("reset"))
end)

hl.define_submap("layout", function()
    hl.bind("E", hl.dsp.layout("togglesplit"))
    hl.bind("R", hl.dsp.layout("swapsplit"))
    hl.bind("Return", hl.dsp.submap("reset"))
    hl.bind("Escape", hl.dsp.submap("reset"))
end)

-- DPMS off
hl.bind("ALT_R + L", hl.dsp.exec_cmd("hyprctl dispatch dpms off"))

-- Screenshot
hl.bind(mod .. " + SHIFT + S",
    hl.dsp.exec_cmd([[sh -lc 'grim -g "$(slurp)" - | wl-copy']]))

-- Power button
hl.bind("XF86PowerOff", hl.dsp.exec_cmd("/usr/local/bin/power-button-action"), { locked = true })
hl.bind("code:124",     hl.dsp.exec_cmd("/usr/local/bin/power-button-action"), { locked = true })

-- Audio
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("uwsm app -- wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("uwsm app -- wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("uwsm app -- wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })

-- Brightness
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("uwsm app -- brightnessctl set 10%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("uwsm app -- brightnessctl set 10%-"), { locked = true, repeating = true })

-- Media keys
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("uwsm app -- playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("uwsm app -- playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("uwsm app -- playerctl previous"),   { locked = true })
