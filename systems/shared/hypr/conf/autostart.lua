hl.on("hyprland.start", function()
  hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
  hl.exec_cmd("uwsm finalize WAYLAND_DISPLAY DISPLAY HYPRLAND_INSTANCE_SIGNATURE XCURSOR_SIZE XCURSOR_THEME SSH_AUTH_SOCK")
  -- qt6ct's style plugin SEGVs under CachyOS's jemalloc preload while
  -- QStyleFactory reads plugin metadata (Qt6CTProxyStyle::reloadSettings),
  -- crash-looping quickshell at startup. Quickshell paints all of its own
  -- chrome in QML, so it loses nothing by dropping the style override; real
  -- Qt apps keep both.
  --
  -- The platform theme has to be swapped rather than emptied, though. With no
  -- platform theme at all Qt never learns an icon theme name, so every
  -- QIcon::fromTheme lookup fails and any tray item that advertises only an
  -- IconName (no IconPixmap) renders as the missing-icon placeholder --
  -- cachy-update is one, steam escapes it only because its icon sits in the
  -- legacy /usr/share/pixmaps path. gtk3 supplies the icon theme from
  -- gtk-icon-theme-name without pulling in qt6ct's crashing style plugin, and
  -- libqgtk3.so ships in qt6-base, which quickshell already depends on.
  hl.exec_cmd("env QT_QPA_PLATFORMTHEME=gtk3 QT_STYLE_OVERRIDE= uwsm app -- quickshell --no-duplicate --config shell")
  hl.exec_cmd("uwsm app -- hypridle")
  hl.exec_cmd("uwsm app -- tailscale systray")
  -- hl.exec_cmd("sleep 10 && uwsm app -- librepods --start-minimized")
end)
