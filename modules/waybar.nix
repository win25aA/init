{ config, pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    roboto
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    playerctl
    pavucontrol
  ];

  fonts.fontconfig.enable = true;

  programs.waybar = {
    enable = true;
    systemd.enable = false;

    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 36;
      exclusive = true;
      passthrough = false;
      gtk-layer-shell = true;
      spacing = 0;
      margin-top = 5;
      margin-left = 7;
      margin-right = 7;

      modules-left = [ "custom/launcher" "hyprland/workspaces" ];
      modules-center = [ "mpris" ];
      modules-right = [ "tray" "pulseaudio" "clock" "custom/power" ];

      "custom/launcher" = {
        format = "";
        tooltip = false;
        on-click = "rofi -show drun";
      };

      "hyprland/workspaces" = {
        format = "{icon}";
        format-icons = {
          active = "";
          default = "";
          urgent = "";
        };
        persistent-workspaces = {
          "DVI-D-1" = [ 1 2 3 4 5 ];
          "HDMI-A-1" = [ 6 7 8 9 10 ];
        };
        on-click = "activate";
        on-scroll-up = "hyprctl dispatch workspace e-1";
        on-scroll-down = "hyprctl dispatch workspace e+1";
        sort-by-number = true;
      };

      mpris = {
        format = "󰎆  {artist}  <span alpha='55%'>•</span>  {title}";
        format-paused = "󰏤  {artist}  <span alpha='55%'>•</span>  {title}";
        format-stopped = "󰝛  No media";
        artist-len = 20;
        title-len = 30;
        dynamic-len = 48;
        dynamic-order = [ "artist" "title" ];
        tooltip-format = "<b>{title}</b>\n{artist} — {album}";
        on-click = "playerctl play-pause";
        on-click-right = "playerctl next";
        on-click-middle = "playerctl previous";
        on-scroll-up = "playerctl next";
        on-scroll-down = "playerctl previous";
      };

      tray = {
        icon-size = 15;
        spacing = 8;
      };

      pulseaudio = {
        format = "{icon} {volume}%";
        format-muted = "󰝟 muted";
        format-icons.default = [ "󰕿" "󰖀" "󰕾" ];
        tooltip-format = "{desc}\nVolume: {volume}%";
        on-click = "pavucontrol";
        on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        scroll-step = 5;
      };

      clock = {
        interval = 1;
        format = "{:%H:%M  •  %d/%m}";
        format-alt = "{:%A, %d %B %Y}";
        tooltip-format = "<tt><small>{calendar}</small></tt>";
        calendar = {
          mode = "month";
          format = {
            months = "<b>{}</b>";
            weekdays = "<span color='#999999'><b>{}</b></span>";
            today = "<span color='#ffffff'><b><u>{}</u></b></span>";
          };
        };
      };

      "custom/power" = {
        format = "󰐥";
        tooltip = false;
        on-click = "wlogout";
      };
    };

    style = ''
      @import "${config.home.homeDirectory}/.config/waybar/matugen-colors.css";

      * {
        font-family: Roboto, "Symbols Nerd Font", sans-serif;
        font-size: 11px;
        font-weight: normal;
        border: none;
        border-radius: 0;
        min-height: 0;
      }

      window#waybar {
        background: alpha(@background, 0.92);
        color: @text;
        border: 1px solid alpha(@outline, 0.28);
        border-radius: 10px;
        box-shadow: 0 3px 12px alpha(#000000, 0.28);
      }

      tooltip {
        background: alpha(@background, 0.98);
        color: @text;
        border: 1px solid alpha(@outline, 0.35);
        border-radius: 9px;
        padding: 8px 10px;
      }

      tooltip label { color: @text; }

      menu {
        background: alpha(@background, 0.98);
        color: @text;
        border: 1px solid alpha(@outline, 0.35);
        border-radius: 9px;
        padding: 5px;
      }

      menu menuitem {
        color: @text;
        border-radius: 7px;
        padding: 6px 11px;
      }

      menu menuitem:hover {
        background: alpha(@primary, 0.16);
        color: @primary;
      }

      #custom-launcher {
        color: @primary;
        background: alpha(@surface_high, 0.78);
        border-right: 1px solid alpha(@outline, 0.24);
        border-radius: 9px 0 0 9px;
        font-size: 15px;
        font-weight: normal;
        padding: 0 15px 0 11px;
        transition: all 160ms ease;
      }

      #custom-launcher:hover {
        color: @on_primary;
        background: @primary;
      }

      #workspaces {
        background: transparent;
        margin: 0 5px;
        padding: 4px 3px;
      }

      #workspaces button {
        color: alpha(@text_muted, 0.72);
        background: transparent;
        border-radius: 7px;
        font-weight: normal;
        margin: 0;
        padding: 0 7px 0 5px;
        transition: all 160ms ease;
      }

      #workspaces button:hover {
        color: @primary;
        background: alpha(@primary, 0.10);
        box-shadow: none;
        text-shadow: none;
      }

      #workspaces button.active {
        color: @primary;
        background: alpha(@primary, 0.14);
      }

      #workspaces button.urgent {
        color: @error;
        background: alpha(@error, 0.14);
      }

      #mpris {
        color: @text;
        font-weight: bold;
        background: alpha(@surface_high, 0.62);
        border: 1px solid alpha(@outline, 0.20);
        border-radius: 8px;
        margin: 4px 0;
        padding: 0 15px;
        min-width: 300px;
        transition: all 160ms ease;
      }

      #mpris:hover {
        color: @primary;
        background: alpha(@surface_high, 0.90);
        border-color: alpha(@primary, 0.38);
      }

      #mpris.paused { color: @text_muted; }

      #tray {
        background: transparent;
        padding: 0 11px;
      }

      #pulseaudio {
        color: @text;
        font-weight: bold;
        background: alpha(@surface_high, 0.52);
        border-left: 1px solid alpha(@outline, 0.20);
        border-right: 1px solid alpha(@outline, 0.20);
        padding: 0 12px;
        transition: all 160ms ease;
      }

      #pulseaudio:hover {
        color: @primary;
        background: alpha(@primary, 0.12);
      }

      #pulseaudio.muted { color: @text_muted; }

      #clock {
        color: @text;
        font-weight: bold;
        background: transparent;
        padding: 0 13px;
      }

      #clock:hover { color: @primary; }

      #custom-power {
        color: @error;
        background: alpha(@error, 0.10);
        border-left: 1px solid alpha(@error, 0.25);
        border-radius: 0 9px 9px 0;
        font-size: 14px;
        font-weight: normal;
        padding: 0 14px 0 12px;
        transition: all 160ms ease;
      }

      #custom-power:hover {
        color: @on_primary;
        background: @error;
      }

      #tray > .passive { -gtk-icon-effect: dim; }
      #tray > .needs-attention { -gtk-icon-effect: highlight; }
    '';
  };
}
