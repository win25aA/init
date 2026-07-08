{ config, pkgs, inputs, ... }:

let
  # Гарантированно правильные иконки через юникод-коды, а не вставленные символы,
  # которые легко бьются при копировании/записи файла.
  nfIcon = code: builtins.fromJSON ''"\u${code}"'';

  iconVolHigh = nfIcon "f028";
  iconVolMute = nfIcon "f026";
  iconWifi = nfIcon "f1eb";
  iconWifiOff = nfIcon "f127";
  iconCpu = nfIcon "f2db";
  iconBattFull = nfIcon "f240";
  iconBatt3 = nfIcon "f241";
  iconBatt2 = nfIcon "f242";
  iconBatt1 = nfIcon "f243";
  iconBattEmpty = nfIcon "f244";
in
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 26;
        spacing = 3;

        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "clock" ];
        modules-right = [ "pulseaudio" "network" "cpu" "memory" "battery" "tray" ];

        "hyprland/workspaces" = {
          format = "{icon}";
          on-click = "activate";
          format-icons = {
            active = "●";
            default = "○";
          };
        };

        clock = {
          format = "{:%H:%M   %d.%m.%Y}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        pulseaudio = {
          format = "${iconVolHigh} {volume}%";
          format-muted = "${iconVolMute} muted";
          on-click = "pamixer -t";
        };

        network = {
          format-wifi = "${iconWifi} {signalStrength}%";
          format-ethernet = "${iconWifi}";
          format-disconnected = "${iconWifiOff} disconnected";
        };

        cpu = {
          format = "${iconCpu} {usage}%";
          interval = 2;
        };

        memory = {
          format = "RAM {}%";
          interval = 2;
        };

        battery = {
          format = "{icon} {capacity}%";
          format-icons = [ iconBattEmpty iconBatt1 iconBatt2 iconBatt3 iconBattFull ];
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
        font-size: 12px;
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
        margin: 4px 2px;
        padding: 0 8px;
        border-radius: 10px;
        transition: all 0.3s ease-in-out;
      }

      #pulseaudio:hover,
      #network:hover,
      #cpu:hover,
      #memory:hover,
      #battery:hover {
        background-color: @surface_variant;
        padding: 0 12px;
      }

      #workspaces {
        background-color: @surface;
        border-radius: 999px;
        padding: 0 4px;
        margin: 4px 2px;
      }

      #workspaces button {
        padding: 0 4px;
        margin: 5px 2px;
        min-width: 6px;
        color: @on_surface_variant;
        background: transparent;
        border-radius: 999px;
        transition: all 0.25s ease-in-out;
      }

      #workspaces button.active {
        color: @primary;
      }

      #workspaces button:hover {
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
