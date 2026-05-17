{ ... }:

{
  xdg.configFile = {
    "hypr/hypridle.conf".source = ./hypridle.conf;
    "hypr/hyprlock.conf".source = ./hyprlock.conf;
    "nwg-dock-hyprland/style.css".text = ''
      window {
        background: rgba(21, 18, 27, 0.82);
        border: 1px solid #96d8ff;
        border-radius: 8px;
        color: #d9e4ff;
        font-family: "JetBrains Mono", "Symbols Nerd Font", sans-serif;
      }

      #box {
        padding: 8px 10px;
      }

      #active {
        border-bottom: 2px solid #96d8ff;
      }

      button,
      image {
        background: transparent;
        border: none;
        box-shadow: none;
        color: #d9e4ff;
      }

      button {
        margin: 0 4px;
        padding: 5px;
        border-radius: 7px;
        font-size: 12px;
      }

      button:hover {
        background: rgba(150, 216, 255, 0.2);
        color: #ffffff;
      }

      button:focus {
        box-shadow: none;
      }
    '';
  };
}
