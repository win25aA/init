{ config, pkgs, inputs, ... }:

let
  nfIcon = code: builtins.fromJSON ''"\u${code}"'';

  iconVolHigh = nfIcon "f028";
  iconVolMute = nfIcon "f026";
  iconWifi = nfIcon "f1eb";
  iconWifiOff = nfIcon "f127";
  iconBluetooth = nfIcon "f294";
  iconPower = nfIcon "f011";
  iconMusic = nfIcon "f001";
  iconPause = nfIcon "f04c";
in
{
  home.packages = with pkgs; [
    playerctl
  ];

  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 28;
        spacing = 0;

        modules-left = [ "hyprland/workspaces" "clock" ];
        modules-center = [ "mpris" ];
        modules-right = [ "network" "bluetooth" "tray" "pulseaudio" "custom/power" ];

        "hyprland/workspaces" = {
          format = "{id}";
          on-click = "activate";
        };

        clock = {
          format = "{:%H:%M}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        mpris = {
          format = "{status_icon} {artist} - {title}";
          format-paused = "${iconPause} {artist} - {title}";
          status-icons = {
            playing = iconMusic;
            paused = iconPause;
          };
          max-length = 40;
        };

        network = {
          format-wifi = "${iconWifi}";
          format-ethernet = "${iconWifi}";
          format-disconnected = "${iconWifiOff}";
          tooltip-format = "{ifname}: {ipaddr}";
          tooltip-format-wifi = "{essid} ({signalStrength}%)";
        };

        bluetooth = {
          format = "${iconBluetooth}";
          format-disabled = "";
          format-connected = "${iconBluetooth} {num_connections}";
          tooltip-format = "{controller_alias}";
        };

        pulseaudio = {
          format = "${iconVolHigh}  {volume}%";
          format-muted = "${iconVolMute}  muted";
          on-click = "pamixer -t";
        };

        tray = {
          spacing = 8;
        };

        "custom/power" = {
          format = "${iconPower}";
          on-click = "hyprctl dispatch exit";
          tooltip = false;
        };
      };
    };

    style = ''
      @import "colors-waybar.css";

      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 13px;
        font-weight: 700;
        border: none;
        border-radius: 0;
      }

      window#waybar {
        background: transparent;
      }

      /* Левая группа: воркспейсы + часы в одной цельной таблетке */
      #workspaces,
      #clock {
        background-color: @surface;
        color: @on_surface;
        margin: 4px 0;
        padding: 0 8px;
      }

      #workspaces {
        margin-left: 4px;
        border-radius: 999px 0 0 999px;
        padding-left: 6px;
        padding-right: 6px;
      }

      #clock {
        margin-right: 4px;
        border-radius: 0 999px 999px 0;
        padding-right: 14px;
      }

      #workspaces button {
        padding: 2px 8px;
        margin: 3px 2px;
        color: @on_surface_variant;
        background-color: @surface_variant;
        border-radius: 999px;
        transition: all 0.25s ease-in-out;
      }

      #workspaces button.active {
        color: @on_primary;
        background-color: @primary;
      }

      #workspaces button:hover {
        background-color: @secondary;
        color: @on_primary;
      }

      /* Центр: медиаплеер */
      #mpris {
        background-color: @surface;
        color: @on_surface;
        margin: 4px 2px;
        padding: 0 14px;
        border-radius: 999px;
      }

      /* Правая группа: сеть + блютус + трей — один цельный блок */
      #network,
      #bluetooth,
      #tray {
        background-color: @surface;
        color: @on_surface;
        margin: 4px 0;
        padding: 0 8px;
      }

      #network {
        margin-left: 4px;
        padding-left: 14px;
        border-radius: 999px 0 0 999px;
      }

      #tray {
        border-radius: 0 999px 999px 0;
        padding-right: 14px;
      }

      /* Громкость — отдельная выделенная "таблетка" акцентным цветом */
      #pulseaudio {
        background-color: @primary;
        color: @on_primary;
        margin: 4px 4px;
        padding: 0 14px;
        border-radius: 999px;
        transition: background-color 0.3s ease-in-out;
      }

      /* Кнопка питания — отдельный кружок справа */
      #custom-power {
        background-color: @surface;
        color: @error;
        margin: 4px 4px 4px 0;
        padding: 0 12px;
        border-radius: 999px;
        transition: all 0.25s ease-in-out;
      }

      #custom-power:hover {
        background-color: @error;
        color: @on_primary;
      }
    '';
  };
}
