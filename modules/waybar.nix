{ config, pkgs, inputs, ... }:

let
  albumArtScript = pkgs.writeShellScript "waybar-albumart" ''
    CACHE="$HOME/.cache/waybar-albumart.jpg"
    URL="$(${pkgs.playerctl}/bin/playerctl metadata mpris:artUrl 2>/dev/null)"

    if [ -z "$URL" ]; then
      echo ""
      exit 0
    fi

    if [[ "$URL" == file://* ]]; then
      echo "''${URL#file://}"
    else
      ${pkgs.curl}/bin/curl -sL "$URL" -o "$CACHE" 2>/dev/null
      echo "$CACHE"
    fi
  '';
in


{
  home.packages = with pkgs; [
    roboto
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    playerctl
    curl
  ];

  fonts.fontconfig.enable = true;

  programs.waybar = {
    enable = true;
    systemd.enable = false;

    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 34;
      spacing = 0;
      margin-top = 6;
      margin-left = 10;
      margin-right = 10;

      modules-left = [ "hyprland/workspaces" "clock" ];
      modules-center = [ "image#albumart" "mpris" ];
      modules-right = [ "tray" "pulseaudio" "battery" "custom/power" ];

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
        format = "{title} ";
        format-paused = " {title} ";
        title-len = 24;
        artist-len = 18;
        tooltip-format = "{player}: {title} - {artist}";
        on-click = "playerctl play-pause";
        on-scroll-up = "playerctl next";
        on-scroll-down = "playerctl previous";
      };

"image#albumart" = {
  exec = "${albumArtScript}";
  size = 28;
  interval = 2;
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

      "custom/power" = {
        format = "󰐥";
        tooltip = false;
        on-click = "wlogout -b 4 -T 300 -B 300 -L 150 -R 150 -p layer-shell";
      };
    };

    style = ''
      @import "${config.home.homeDirectory}/.config/waybar/matugen-colors.css";

      * {
        font-family: sans-serif, "Symbols Nerd Font";
        font-size: 12px;
        font-weight: 900;
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

      window.popup,
      window.popup decoration {
        background: transparent;
        border-radius: 12px;
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

      #image {
        background: @surface;
        margin: 4px 0;
        padding: 3px 0 3px 8px;
        border-radius: 10px 0 0 10px;
      }

      #mpris {
        color: @text;
        background: @surface;
        border-radius: 0 10px 10px 0;
        margin: 4px 0;
        padding: 0 14px 0 10px;
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      }

      #mpris:hover {
        background: @primary;
        color: @on_primary;
      }

      #mpris.paused {
        color: @text_muted;
      }

      #mpris.paused:hover {
        color: @on_primary;
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
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      }

      #pulseaudio:hover {
        background: @primary;
        color: @on_primary;
      }

      #battery {
        color: @text;
        padding: 0 8px;
        margin-right: 8px;
      }

      #pulseaudio.muted {
        color: @text_muted;
      }

      #custom-power {
        color: @primary;
        background: @surface;
        border-radius: 10px;
        margin: 4px 8px 4px 0;
        padding: 0 10px;
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      }

      #custom-power:hover {
        color: @on_primary;
        background: @primary;
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
