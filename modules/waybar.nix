{ config, pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    roboto
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    playerctl
  ];

  fonts.fontconfig.enable = true;

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
      modules-right = [ "tray" "pulseaudio" "battery" ];

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
            months = "<b>{}</b>";
            today = "<b><u>{}</u></b>";
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
        format = "<span size='140%'>{icon}</span> {volume}%";
        format-muted = "<span size='140%'>󰝟</span> {volume}%";
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
    };

    style = ''
      @import "${config.home.homeDirectory}/.config/waybar/matugen-colors.css";

      * {
        font-family: sans-serif, "Symbols Nerd Font";
        font-size: 12px;
        font-weight: 700;
        border: none;
        border-radius: 0;
        min-height: 0;
      }

      window#waybar {
        background: alpha(@background, 0.85);
        border-radius: 14px;
        color: @text;
      }

      tooltip {
        background: @background;
        border: 1px solid @primary;
        border-radius: 10px;
        color: @text;
      }

      menu {
        background: @background;
        border: 1px solid alpha(@primary, 0.5);
        border-radius: 12px;
        padding: 6px;
      }

      menu menuitem {
        background: transparent;
        color: @text;
        border-radius: 8px;
        padding: 6px 12px;
        transition: all 0.15s ease;
      }

      menu menuitem:hover {
        background: @primary;
        color: @on_primary;
      }

      menu menuitem:disabled {
        color: @outline;
      }

      menu separator {
        background: alpha(@outline, 0.4);
        min-height: 1px;
        margin: 4px 6px;
      }

      #workspaces {
        background: @surface;
        border-radius: 10px;
        margin: 4px 6px 4px 8px;
        padding: 0 4px;
      }

      #workspaces button {
        color: @text_muted;
        background: transparent;
        border-radius: 8px;
        margin: 3px 2px;
        padding: 0 8px;
        transition: all 0.2s ease;
      }

      #workspaces button.active {
        color: @on_primary;
        background: @primary;
      }

      #workspaces button:hover {
        color: @primary;
        background: @surface_high;
      }

      #workspaces button.urgent {
        color: @on_primary;
        background: @error;
      }

      #clock {
        color: @primary;
        padding: 0 10px;
      }

      #mpris {
        color: @text;
        background: @surface;
        border-radius: 10px;
        margin: 4px 0;
        padding: 0 14px;
      }

      #mpris.paused {
        color: @text_muted;
      }

      #tray {
        background: @surface;
        border-radius: 10px;
        margin: 4px 6px;
        padding: 0 10px;
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #pulseaudio {
        color: @text;
        background: @surface;
        border-radius: 10px;
        margin: 4px 6px 4px 0;
        padding: 0 11px;
      }

      #battery {
        color: @text;
        padding: 0 8px;
        margin-right: 8px;
      }

      #pulseaudio.muted {
        color: @text_muted;
      }

      #battery.warning {
        color: @secondary;
      }

      #battery.critical {
        color: @error;
      }

      #battery.charging {
        color: @tertiary;
      }
    '';
  };
}
