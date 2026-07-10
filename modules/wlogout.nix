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
        font-family: sans-serif, "Symbols Nerd Font";
        background-image: none;
        box-shadow: none;
        text-shadow: none;
      }

      window {
        background-color: alpha(@background, 0.55);
      }

      button {
        font-size: 52px;
        font-weight: 900;
        color: @text;
        background-color: alpha(@surface, 0.95);
        border: 2px solid transparent;
        border-radius: 24px;
        margin: 10px;
        transition: all 0.2s ease;
      }

      button:focus {
        border-color: alpha(@primary, 0.6);
        color: @primary;
      }

      button:hover {
        background-color: @primary;
        color: @on_primary;
        border-color: transparent;
        margin: 4px;
      }

      #shutdown:hover {
        background-color: @error;
      }
    '';
  };
}
