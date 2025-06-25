{
  pkgs,
  ...
}: {
  services.aerospace = {
    enable = true;
    package = pkgs.aerospace;

    settings= {
      enable-normalization-flatten-containers = true;
      enable-normalization-opposite-orientation-for-nested-containers = true;

      on-focused-monitor-changed = ["move-mouse monitor-lazy-center"];
      on-focus-changed = [
        "move-mouse window-lazy-center"
      ];

      automatically-unhide-macos-hidden-apps = false;

      accordion-padding = 30;
      default-root-container-layout = "tiles";
      default-root-container-orientation = "auto";

      gaps = {
        outer.bottom = 0;
        outer.top = 0;
                outer.left = 1;
        outer.right = 1;
        inner.horizontal = 3;
        inner.vertical = 3;
      };

      workspace-to-monitor-force-assignment = {
        "1" = "main";
        "2" = "main";
        "3" = "main";
        "4" = "main";
        "5" = "main";
        "6" = ["LG HDR 4K" "main"];
        "7" = ["LG HDR 4K" "main"];
        "8" = ["LG HDR 4K" "main"];
        "9" = ["built-in" "main"];
        "0" = ["built-in" "main"];
      };

      key-mapping.preset = "qwerty";
      mode.main.binding = {
        alt-1 = "workspace 1";
        alt-2 = "workspace 2";
        alt-3 = "workspace 3";
        alt-4 = "workspace 4";
        alt-5 = "workspace 5";
        alt-f1 = "workspace 6";
        alt-f2 = "workspace 7";
        alt-f3 = "workspace 8";
        alt-6 = "workspace 9";
        alt-f4 = "workspace 0";

        alt-shift-p = "workspace --wrap-around prev";
        alt-shift-n = "workspace --wrap-around next";

        # Move windows to workspaces and follow
        alt-shift-1 = ["move-node-to-workspace 1" "workspace 1"];
        alt-shift-2 = ["move-node-to-workspace 2" "workspace 2"];
        alt-shift-3 = ["move-node-to-workspace 3" "workspace 3"];
        alt-shift-4 = ["move-node-to-workspace 4" "workspace 4"];
        alt-shift-5 = ["move-node-to-workspace 5" "workspace 5"];
        alt-shift-f1 = ["move-node-to-workspace 6" "workspace 6"];
        alt-shift-f2 = ["move-node-to-workspace 7" "workspace 7"];
        alt-shift-f3 = ["move-node-to-workspace 8" "workspace 8"];
        alt-shift-6 = ["move-node-to-workspace 9" "workspace 9"];
        alt-shift-f4 = ["move-node-to-workspace 0" "workspace 0"];

        # Window focus navigation
        alt-left = "focus --boundaries-action wrap-around-the-workspace left";
        alt-right = "focus --boundaries-action wrap-around-the-workspace right";
        alt-up = "focus --boundaries-action wrap-around-the-workspace up";
        alt-down = "focus --boundaries-action wrap-around-the-workspace down";

        # Move windows within workspace
        alt-shift-left = "move left";
        alt-shift-right = "move right";
        alt-shift-up = "move up";
        alt-shift-down = "move down";

        # Horizontal monitor management (left/right for multi-monitor setup)
        alt-shift-cmd-right = "move-node-to-monitor right";
        alt-shift-cmd-left = "move-node-to-monitor left";

        # Monitor focus switching (horizontal only)
        alt-cmd-left = "focus-monitor left";
        alt-cmd-right = "focus-monitor right";

        # Layout management
        alt-shift-space = "layout floating tiling";
        alt-f = "layout floating tiling";

        # Monitor layout management
        alt-m = "exec-and-forget /opt/homebrew/bin/hs -c 'MonitorManager.fix()'";

        # Development-focused app launches
        alt-enter = "exec-and-forget open -na WezTerm";
        alt-b = "exec-and-forget open -na \"Google Chrome\" --args --new-window";

        # System utilities
        alt-l = "exec-and-forget pmset displaysleepnow";
        alt-shift-q = "close --quit-if-last-window";
        
        # Screenshot utilities
        cmd-shift-x = "exec-and-forget /etc/profiles/per-user/C.Hessel/bin/flameshot gui";
        cmd-shift-a = "exec-and-forget /etc/profiles/per-user/C.Hessel/bin/flameshot full -c";

        # Disable unwanted cmd+letter bindings that conflict with apps
        cmd-b = []; # Disable default workspace B binding
        cmd-l = []; # Disable default workspace L binding
        cmd-r = []; # Disable default workspace R binding

        # Mode switching
        alt-r = "mode resize";
        alt-shift-comma = "mode layout";
        alt-shift-period = "mode monitor";
      };

      mode.resize.binding = {
        left = "resize width +50";
        right = "resize width -50";
        up = "resize height +50";
        down = "resize height -50";
        # Fine-grained resizing
        shift-left = "resize width +10";
        shift-right = "resize width -10";
        shift-up = "resize height +10";
        shift-down = "resize height -10";
        enter = "mode main";
        esc = "mode main";
      };

      mode.layout.binding = {
        esc = "mode main";
        enter = "mode main";
        r = "flatten-workspace-tree";
        # Window joining
        alt-left = "join-with left";
        alt-right = "join-with right";
        alt-up = "join-with up";
        alt-down = "join-with down";
        # Layout presets
        alt-s = "layout v_accordion";
        alt-w = "layout h_accordion";
        alt-e = "layout tiles horizontal vertical";
      };

      # Monitor management mode
      mode.monitor.binding = {
        esc = "mode main";
        enter = "mode main";
        # Quick workspace assignments per monitor
        "1" = "move-node-to-monitor 1";  # Ultra-wide
        "2" = "move-node-to-monitor 2";  # Laptop
        "3" = "move-node-to-monitor 3";  # QHD
        # Focus monitor directly (horizontal only)
        left = "focus-monitor left";
        right = "focus-monitor right";
      };

      # App placement rules (simplified - just workspace assignment)
      on-window-detected = [
        # PRIMARY CODING APPS
        {
          "if" = {
            "app-id" = "com.todesktop.230313mzl4w4u92";  # Cursor
          };
          "run" = "move-node-to-workspace 1";
        }
        {
          "if" = {
            "app-id" = "com.apple.dt.Xcode";
          };
          "run" = "move-node-to-workspace 1";
        }
        {
          "if" = {
            "app-id" = "com.jetbrains.PhpStorm";
          };
          "run" = "move-node-to-workspace 1";
        }
        
        # TERMINAL - Goes to coding workspace
        {
          "if" = {
            "app-id" = "com.github.wez.wezterm";
          };
          "run" = "move-node-to-workspace 7";
        }
        
        # BROWSERS
        {
          "if".app-name-regex-substring = "Google.Chrome";
          "run" = "move-node-to-workspace 1";
        }
        {
          "if" = {
            "app-id" = "org.mozilla.firefox";
          };
          "run" = "move-node-to-workspace 6";
        }
        {
          "if" = {
            "app-id" = "com.apple.Safari";
          };
          "run" = "move-node-to-workspace 6";
        }
        
        # COMMUNICATION
        {
          "if" = {
            "app-id" = "com.tinyspeck.slackmacgap";
          };
          "run" = "move-node-to-workspace 9";
        }
        {
          "if" = {
            "app-id" = "com.microsoft.teams2";
          };
          "run" = "move-node-to-workspace 0";
        }
        {
          "if" = {
            "app-id" = "com.microsoft.Teams";
          };
          "run" = "move-node-to-workspace 0";
        }
        
        # UTILITIES
        {
          "if" = {
            "app-id" = "md.obsidian";
          };
          "run" = "move-node-to-workspace 7";
        }
        {
          "if" = {
            "app-id" = "com.apple.ActivityMonitor";
          };
          "run" = "move-node-to-workspace 8";
        }
      ];
    };
  };
}

