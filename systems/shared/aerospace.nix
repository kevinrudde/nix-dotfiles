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

      key-mapping.preset = "qwerty";
      mode.main.binding = {
        alt-1 = "workspace 1";
        alt-2 = "workspace 2";
        alt-3 = "workspace 3";
        alt-4 = "workspace 4";
        alt-5 = "workspace 5";
        alt-6 = "workspace 6";

        alt-shift-p = "workspace --wrap-around prev";
        alt-shift-n = "workspace --wrap-around next";

        alt-shift-1 = ["move-node-to-workspace 1" "workspace 1"];
        alt-shift-2 = ["move-node-to-workspace 2" "workspace 2"];
        alt-shift-3 = ["move-node-to-workspace 3" "workspace 3"];
        alt-shift-4 = ["move-node-to-workspace 4" "workspace 4"];
        alt-shift-5 = ["move-node-to-workspace 5" "workspace 5"];
        alt-shift-6 = ["move-node-to-workspace 6" "workspace 6"];

        alt-left = "focus --boundaries-action wrap-around-the-workspace left";
        alt-right = "focus --boundaries-action wrap-around-the-workspace right";
        alt-up = "focus --boundaries-action wrap-around-the-workspace up";
        alt-down = "focus --boundaries-action wrap-around-the-workspace down";

        alt-shift-left = "move left";
        alt-shift-right = "move right";
        alt-shift-up = "move up";
        alt-shift-down = "move down";

        alt-shift-cmd-right = "move-node-to-monitor right";
        alt-shift-cmd-left = "move-node-to-monitor left";

        alt-shift-space = "layout floating tiling";
        alt-f = "layout floating tiling";

        alt-enter = "exec-and-forget open -na WezTerm";
        alt-b = "exec-and-forget open -na \"Google Chrome\" --args --new-window";

        alt-l = "exec-and-forget pmset displaysleepnow";

        alt-shift-q = "close --quit-if-last-window";

        alt-r = "mode resize";
        alt-shift-comma = "mode layout";
      };

      mode.resize.binding = {
        left = "resize width +50";
        right = "resize width -50";
        up = "resize height +50";
        down = "resize height -50";
        enter = "mode main";
        esc = "mode main";
      };

      mode.layout.binding = {
        esc = "mode  main";
        enter = "mode main";
        r = "flatten-workspace-tree";
        alt-left = "join-with left";
        alt-right = "join-with right";
        alt-up = "join-with up";
        alt-down = "join-with down";
        alt-s = "layout v_accordion";
        alt-w = "layout h_accordion";
        alt-e = "layout tiles horizontal vertical";
      };
    };
  };
}
