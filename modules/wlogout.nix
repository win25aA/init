{ config, pkgs, inputs, ... }:

{
  programs.wlogout = {
    enable = true;

    layout = [
      {
        label = "logout";
        action = "hyprctl dispatch exit";
        text = "󰍃";
        keybind = "l";
      }
      {
        label = "suspend";
        action = "systemctl suspend";
        text = "󰤄";
        keybind = "s";
      }
      {
        label = "reboot";
        action = "systemctl reboot";
        text = "󰜉";
        keybind = "r";
      }
      {
        label = "shutdown";
        action = "systemctl poweroff";
        text = "󰐥";
        keybind = "p";
      }
    ];

    style = ''
      @import "${config.home.homeDirectory}/.config/waybar/matugen-colors.css";

      * {
        font-family: "Symbols Nerd Font", Roboto, sans-serif;
        background-image: none;
        border-image: none;
        box-shadow: none;
        text-shadow: none;
        outline: none;
        border: none;
      }

      window {
        background-color: alpha(@background, 0.68);
      }

      button {
        color: @text;
        background-color: alpha(@surface, 0.94);
        border: 1px solid alpha(@outline, 0.28);
        border-radius: 16px;
        margin: 8px;
        font-size: 46px;
        font-weight: normal;
        transition: all 180ms ease;
      }

      button:focus {
        color: @primary;
        background-color: alpha(@surface_high, 0.96);
        border-color: alpha(@primary, 0.46);
      }

      button:hover {
        color: @on_primary;
        background-color: @primary;
        border-color: @primary;
      }

      #shutdown:hover {
        color: @on_primary;
        background-color: @error;
        border-color: @error;
      }
    '';
  };
}
