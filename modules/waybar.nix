{ config, pkgs, inputs, ... }:

{
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 34;
      spacing = 0;
      margin-top = 6;
      margin-left = 10;
      margin-right = 10;

      modules-left = [ "hyprland/workspaces" "clock" ];
      modules-center = [ "mpris" ];
      modules-right = [ "tray" "pulseaudio" "battery" "idle_inhibitor" "custom/power" ];

      "hyprland/workspaces" = {
        format = "{name}";
        on-click = "activate";
        on-scroll-up = "hyprctl dispatch workspace e-1";
        on-scroll-down = "hyprctl dispatch workspace e+1";
        sort-by-number = true;
      };

      clock = {
        format = "{:%H:%M}";
        format-alt = "{:%A, %d %B %Y}";
        tooltip-format = "<tt><small>{calendar}</small></tt>";
        calendar = {
          mode = "month";
          format = {
            months = "<span color='#f2b3c9'><b>{}</b></span>";
            days = "<span color='#e8dfe2'>{}</span>";
            weekdays = "<span color='#d5a8b8'>{}</span>";
            today = "<span color='#f2b3c9'><b><u>{}</u></b></span>";
          };
        };
      };

      mpris = {
        format = "🎵 {title} - {artist}";
        format-paused = "  {title} - {artist}";
        title-len = 24;
        artist-len = 18;
        tooltip-format = "{player}: {title} - {artist}";
        on-click = "playerctl play-pause";
        on-scroll-up = "playerctl next";
        on-scroll-down = "playerctl previous";
      };

      tray = {
        icon-size = 16;
        spacing = 8;
      };

      pulseaudio = {
        format = "{icon}";
        format-muted = "󰝟";
        format-icons.default = [ "󰕿" "󰖀" "󰕾" ];
        tooltip-format = "{desc}: {volume}%";
        on-click = "pavucontrol";
        on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        scroll-step = 5;
      };

      battery = {
        states = { warning = 30; critical = 15; };
        format = "{capacity}% {icon}";
        format-charging = "{capacity}% 󰂄";
        format-plugged = "{capacity}% 󰚥";
        format-icons = [ "󰁺" "󰁼" "󰁾" "󰂀" "󰁹" ];
        tooltip-format = "{timeTo}";
      };

      idle_inhibitor = {
        format = "{icon}";
        format-icons = {
          activated = "󰅶";
          deactivated = "󰾪";
        };
        tooltip-format-activated = "Idle inhibitor: on";
        tooltip-format-deactivated = "Idle inhibitor: off";
      };

      "custom/power" = {
        format = "󰐥";
        tooltip = false;
        on-click = "wlogout";
      };
    };

    style = ''
      * {
        font-family: "JetBrains Mono Nerd Font";
        font-size: 12px;
        font-weight: bold;
        border: none;
        border-radius: 0;
        min-height: 0;
      }

      window#waybar {
        background: rgba(20, 13, 16, 0.85);
        border-radius: 14px;
        color: #e8dfe2;
      }

      tooltip {
        background: #1e1418;
        border: 1px solid #f2b3c9;
        border-radius: 10px;
        color: #e8dfe2;
      }

      #workspaces {
        background: #2b2126;
        border-radius: 10px;
        margin: 4px 6px 4px 8px;
        padding: 0 4px;
      }

      #workspaces button {
        color: #b8a8ae;
        background: transparent;
        border-radius: 8px;
        margin: 3px 2px;
        padding: 0 8px;
        transition: all 0.2s ease;
      }

      #workspaces button.active {
        color: #2b1219;
        background: #f2b3c9;
      }

      #workspaces button:hover {
        color: #f2b3c9;
        background: #3a2c33;
      }

      #workspaces button.urgent {
        color: #2b1219;
        background: #ffb4ab;
      }

      #clock {
        color: #f2b3c9;
        padding: 0 10px;
      }

      #mpris {
        color: #e8dfe2;
        background: #2b2126;
        border-radius: 10px;
        margin: 4px 0;
        padding: 0 14px;
      }

      #mpris.paused {
        color: #b8a8ae;
      }

      #tray {
        background: #2b2126;
        border-radius: 10px;
        margin: 4px 6px;
        padding: 0 10px;
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #pulseaudio,
      #battery,
      #idle_inhibitor {
        color: #e8dfe2;
        padding: 0 8px;
      }

      #pulseaudio.muted {
        color: #b8a8ae;
      }

      #battery.warning {
        color: #ffdca8;
      }

      #battery.critical {
        color: #ffb4ab;
      }

      #battery.charging {
        color: #b6e3a8;
      }

      #custom-power {
        color: #f2b3c9;
        background: #2b2126;
        border-radius: 10px;
        margin: 4px 8px 4px 4px;
        padding: 0 10px;
      }

      #custom-power:hover {
        color: #2b1219;
        background: #f2b3c9;
      }
    '';
  };
}
