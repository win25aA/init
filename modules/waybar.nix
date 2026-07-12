{ config, pkgs, inputs, ... }:

let
  resourceRing = pkgs.writeShellApplication {
    name = "waybar-resource-ring";
    runtimeInputs = with pkgs; [ coreutils gawk ];

    text = ''
      set -euo pipefail

      mode="$1"
      cache_dir="$HOME/.cache/waybar-rings"
      colors_file="$HOME/.config/waybar/matugen-colors.css"
      mkdir -p "$cache_dir"

      get_color() {
        local name="$1"
        local fallback="$2"
        local value=""

        if [[ -f "$colors_file" ]]; then
          value="$(awk -v wanted="$name" \
            '$1 == "@define-color" && $2 == wanted { gsub(";", "", $3); print $3; exit }' \
            "$colors_file" 2>/dev/null || true)"
        fi

        if [[ -n "$value" ]]; then
          printf '%s' "$value"
        else
          printf '%s' "$fallback"
        fi
      }

      if [[ "$mode" == "cpu" ]]; then
        read_cpu() {
          read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
          cpu_total=$((user + nice + system + idle + iowait + irq + softirq + steal))
          cpu_idle=$((idle + iowait))
        }

        read_cpu
        total_before="$cpu_total"
        idle_before="$cpu_idle"
        sleep 0.15
        read_cpu
        total_after="$cpu_total"
        idle_after="$cpu_idle"

        total_delta=$((total_after - total_before))
        idle_delta=$((idle_after - idle_before))
        percent=0
        if (( total_delta > 0 )); then
          percent=$((100 * (total_delta - idle_delta) / total_delta))
        fi

        label="CPU"
        accent="$(get_color primary '#d0bcff')"
        output="$cache_dir/cpu.svg"
      else
        total="$(awk '/^MemTotal:/ { print $2 }' /proc/meminfo)"
        available="$(awk '/^MemAvailable:/ { print $2 }' /proc/meminfo)"
        percent=$((100 * (total - available) / total))

        label="RAM"
        accent="$(get_color secondary '#ccc2dc')"
        output="$cache_dir/memory.svg"
      fi

      (( percent < 0 )) && percent=0
      (( percent > 100 )) && percent=100

      track="$(get_color surface_high '#3a3540')"
      text="$(get_color text '#ffffff')"
      temporary="$output.tmp.$$"

      cat > "$temporary" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32">
  <circle cx="16" cy="16" r="13" fill="none" stroke="$track" stroke-width="3"/>
  <circle cx="16" cy="16" r="13" fill="none" stroke="$accent" stroke-width="3"
          pathLength="100" stroke-dasharray="$percent 100" stroke-linecap="round"
          transform="rotate(-90 16 16)"/>
  <text x="16" y="19.3" text-anchor="middle" fill="$text"
        font-family="Roboto, sans-serif" font-size="10" font-weight="900"
        letter-spacing="-0.55">$percent%</text>
</svg>
EOF

      mv -f "$temporary" "$output"
      printf '%s\n%s: %s%%\n' "$output" "$label" "$percent"
    '';
  };
in
{
  home.packages = (with pkgs; [
      roboto
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
      playerctl
      pavucontrol
    ]) ++ [ resourceRing ];

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

      modules-left = [
        "custom/launcher"
        "hyprland/workspaces"
        "image#cpu"
        "image#memory"
      ];
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
          default = "";
          empty = "";
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

      "image#cpu" = {
        exec = "${resourceRing}/bin/waybar-resource-ring cpu";
        size = 32;
        interval = 2;
        tooltip = true;
        on-click = "kitty -e btop";
      };

      "image#memory" = {
        exec = "${resourceRing}/bin/waybar-resource-ring memory";
        size = 32;
        interval = 2;
        tooltip = true;
        on-click = "kitty -e btop";
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
        on-click = "wlogout -b 4";
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

      /* GTK рисует popup в отдельном прямоугольном окне. Делаем
         внешний слой полностью прозрачным, чтобы не было квадратных углов. */
      window.popup,
      window.popup decoration,
      window.popup > decoration {
        background: transparent;
        background-color: transparent;
        background-image: none;
        border: none;
        box-shadow: none;
      }

      window.popup menu,
      menu {
        background: alpha(@background, 0.98);
        background-image: none;
        color: @text;
        border: 1px solid alpha(@outline, 0.35);
        border-radius: 11px;
        box-shadow: none;
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
        font-family: "Symbols Nerd Font";
        font-size: 15px;
        font-weight: normal;
        min-width: 38px;
        padding: 0;
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
        font-family: "Symbols Nerd Font";
        font-weight: normal;
        min-width: 26px;
        margin: 0;
        padding: 0;
        transition: all 160ms ease;
      }

      #workspaces button:hover {
        color: @primary;
        background: alpha(@primary, 0.10);
        box-shadow: none;
        text-shadow: none;
      }

      #workspaces button.empty {
        color: alpha(@text_muted, 0.35);
      }

      #workspaces button.active {
        color: @primary;
        background: alpha(@primary, 0.14);
      }

      #workspaces button.urgent {
        color: @error;
        background: alpha(@error, 0.14);
      }

      #image.cpu {
        margin-left: 3px;
      }

      #image.cpu,
      #image.memory {
        padding: 0 1px;
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
        font-family: "Symbols Nerd Font";
        font-size: 14px;
        font-weight: normal;
        min-width: 38px;
        padding: 0;
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
