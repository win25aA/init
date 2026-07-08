{ config, pkgs, inputs, ... }:

{
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 34;
        spacing = 4;

        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "clock" ];
        modules-right = [ "pulseaudio" "network" "cpu" "memory" "battery" "tray" ];

        "hyprland/workspaces" = {
          format = "{icon}";
          on-click = "activate";
          format-icons = {
            active = "";
            default = "";
          };
        };

        clock = {
          format = "{:%H:%M   %d.%m.%Y}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        pulseaudio = {
          format = "{icon}  {volume}%";
          format-muted = "  muted";
          format-icons = {
            default = [ "" "" "" ];
          };
          on-click = "pamixer -t";
        };

        network = {
          format-wifi = "  {signalStrength}%";
          format-ethernet = "";
          format-disconnected = "⚠ disconnected";
        };

        cpu = {
          format = "  {usage}%";
          interval = 2;
        };

        memory = {
          format = "  {}%";
          interval = 2;
        };

        battery = {
          format = "{icon}  {capacity}%";
          format-icons = [ "" "" "" "" "" ];
          states = {
            warning = 30;
            critical = 15;
          };
        };

        tray = {
          spacing = 8;
        };
      };
    };

    style = ''
      @import "colors-waybar.css";

      * {
        font-family: "JetBrains Mono Nerd Font";
        font-size: 13px;
        border: none;
        border-radius: 0;
      }

      window#waybar {
        background: transparent;
      }

      #workspaces,
      #clock,
      #pulseaudio,
      #network,
      #cpu,
      #memory,
      #battery,
      #tray {
        background-color: @surface;
        color: @on_surface;
        margin: 5px 3px;
        padding: 0 10px;
        border-radius: 12px;
      }

      #workspaces button {
        padding: 0 6px;
        color: @on_surface_variant;
        background: transparent;
      }

      #workspaces button.active {
        color: @on_primary;
        background-color: @primary;
        border-radius: 10px;
      }

      #workspaces button:hover {
        background-color: @surface_variant;
        border-radius: 10px;
      }

      #battery.warning {
        color: @tertiary;
      }

      #battery.critical {
        color: @error;
      }
    '';
  };
}
