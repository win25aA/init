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
          format = "{icon} {volume}%";
          format-muted = " muted";
          format-icons = {
            default = [ "" "" "" ];
          };
          on-click = "pamixer -t";
        };

        network = {
          format-wifi = " {signalStrength}%";
          format-ethernet = "";
          format-disconnected = " disconnected";
        };

        cpu = {
          format = " {usage}%";
          interval = 2;
        };

        memory = {
          format = " {}%";
          interval = 2;
        };

        battery = {
          format = "{icon} {capacity}%";
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
        font-family: "JetBrainsMono Nerd Font";
        font-size: 16px;
        font-weight: 700;
        border: none;
        border-radius: 0;
      }

      window#waybar {
        background: transparent;
      }

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
        transition: all 0.3s ease-in-out;
      }

      #pulseaudio:hover,
      #network:hover,
      #cpu:hover,
      #memory:hover,
      #battery:hover {
        background-color: @surface_variant;
        padding: 0 14px;
      }

      /* Единая полоса воркспейсов, как в noctalia — один общий фон,
         кнопки внутри просто меняют цвет, а не сидят отдельными капсулами */
      #workspaces {
        background-color: @surface;
        border-radius: 999px;
        padding: 0 6px;
        margin: 5px 3px;
      }

      #workspaces button {
        padding: 0 8px;
        margin: 6px 3px;
        min-width: 10px;
        color: @on_surface_variant;
        background: transparent;
        border-radius: 999px;
        transition: all 0.25s ease-in-out;
      }

      #workspaces button.active {
        color: @on_primary;
        background-color: @primary;
        min-width: 22px;
      }

      #workspaces button:hover {
        background-color: @surface_variant;
        color: @on_surface;
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
