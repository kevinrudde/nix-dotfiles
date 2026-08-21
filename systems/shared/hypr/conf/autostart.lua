hl.on("hyprland.start", function()
  hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
  hl.exec_cmd("uwsm finalize WAYLAND_DISPLAY DISPLAY HYPRLAND_INSTANCE_SIGNATURE XCURSOR_SIZE XCURSOR_THEME SSH_AUTH_SOCK")
  -- qt6ct's style plugin SEGVs under CachyOS's jemalloc preload while
  -- QStyleFactory reads plugin metadata (Qt6CTProxyStyle::reloadSettings),
  -- crash-looping quickshell at startup. Quickshell paints all of its own
  -- chrome in QML, so it loses nothing by skipping the platform theme and
  -- style override; real Qt apps keep both.
  hl.exec_cmd("env QT_QPA_PLATFORMTHEME= QT_STYLE_OVERRIDE= uwsm app -- quickshell --no-duplicate --config shell")
  hl.exec_cmd("uwsm app -- hypridle")
  hl.exec_cmd("uwsm app -- tailscale systray")
  -- hl.exec_cmd("sleep 10 && uwsm app -- librepods --start-minimized")
end)
