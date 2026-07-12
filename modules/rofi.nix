{ config, pkgs, inputs, ... }:

let
  wallpaperSelector = pkgs.writeShellApplication {
    name = "wallpaper-selector";

    runtimeInputs = with pkgs; [
      rofi
      imagemagick
      matugen
      awww
      coreutils
      findutils
      procps
      waybar
      libnotify
    ];

    text = ''
      set -euo pipefail

      wallpaper_dir="/etc/nixos/wallpapers"
      cache_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/rofi-wallpapers"
      current_link="''${XDG_CACHE_HOME:-$HOME/.cache}/current-wallpaper"
      state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}"
      log_file="$state_dir/wallpaper-selector.log"

      if [[ ! -d "$wallpaper_dir" ]]; then
        printf 'Wallpaper directory not found: %s\n' "$wallpaper_dir" >&2
        exit 1
      fi

      mkdir -p "$cache_dir" "$state_dir"

      build_entries() {
        while IFS= read -r -d $'\0' wallpaper; do
          relative="''${wallpaper#"$wallpaper_dir"/}"
          hash="$(printf '%s' "$wallpaper" | sha256sum | cut -d ' ' -f 1)"
          thumbnail="$cache_dir/$hash.png"

          if [[ ! -f "$thumbnail" || "$wallpaper" -nt "$thumbnail" ]]; then
            magick "$wallpaper" \
              -auto-orient \
              -thumbnail '320x180^' \
              -gravity center \
              -extent 320x180 \
              "$thumbnail"
          fi

          printf '%s\0icon\x1f%s\n' "$relative" "$thumbnail"
        done < <(
          find "$wallpaper_dir" -type f \
            \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
            -print0 | sort -z
        )
      }

      selected="$(
        build_entries | rofi \
          -dmenu \
          -i \
          -show-icons \
          -p "Wallpaper" \
          -theme "$HOME/.config/rofi/wallpaper.rasi"
      )" || exit 0

      [[ -n "$selected" ]] || exit 0

      wallpaper="$wallpaper_dir/$selected"
      [[ -f "$wallpaper" ]] || exit 1

      awww img "$wallpaper" \
        --transition-type grow \
        --transition-pos 0.5,0.5 \
        --transition-duration 1.1 \
        --transition-fps 60

      ln -sfn "$wallpaper" "$current_link"

      if ! matugen image "$wallpaper" -m dark --source-color-index 0 >"$log_file" 2>&1; then
        notify-send -u critical \
          "Matugen не применился" \
          "Ошибка записана в $log_file"
        exit 1
      fi

      # В NixOS процесс может называться .waybar-wrapped, поэтому -x его не находил.
      pkill -f '[w]aybar' || true

      for _ in $(seq 1 20); do
        pgrep -f '[w]aybar' >/dev/null || break
        sleep 0.05
      done

      nohup waybar >"''${XDG_RUNTIME_DIR:-/tmp}/waybar.log" 2>&1 &

      notify-send \
        "Обои обновлены" \
        "Matugen применён, Waybar перезапущен"
    '';
  };
in
{
  home.packages = [ wallpaperSelector ];

  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    font = "Roboto Bold 12";
    location = "center";
    terminal = "${pkgs.kitty}/bin/kitty";
    extraConfig = {
      modi = "drun,run";
      show-icons = true;
      drun-display-format = "{name}";
    };
    theme = "${config.xdg.configHome}/rofi/theme.rasi";
  };

  xdg.configFile."rofi/theme.rasi".text = ''
    @import "~/.config/rofi/matugen-colors.rasi"

    * {
      background-color: transparent;
      text-color: @text;
    }

    window {
      transparency: "real";
      background-color: @background-trans;
      border: 1px;
      border-color: @outline;
      border-radius: 16px;
      width: 460px;
      padding: 14px;
    }

    mainbox {
      spacing: 12px;
      children: [ inputbar, listview ];
    }

    inputbar {
      background-color: @surface;
      border-radius: 12px;
      padding: 10px 14px;
      children: [ entry ];
    }

    entry {
      placeholder: "Поиск...";
      placeholder-color: @text-muted;
      cursor: text;
    }

    listview {
      lines: 6;
      columns: 1;
      spacing: 6px;
      scrollbar: false;
      fixed-height: false;
    }

    element {
      border-radius: 10px;
      padding: 8px 12px;
      spacing: 12px;
    }

    element selected.normal,
    element selected.active,
    element selected.urgent {
      background-color: @primary;
      text-color: @on-primary;
    }

    element-icon { size: 26px; }

    element-text {
      text-color: inherit;
      vertical-align: 0.5;
      highlight: bold;
    }
  '';

  xdg.configFile."rofi/wallpaper.rasi".text = ''
    @import "~/.config/rofi/matugen-colors.rasi"

    * {
      background-color: transparent;
      text-color: @text;
    }

    window {
      transparency: "real";
      location: center;
      anchor: center;
      width: 920px;
      background-color: @background-trans;
      border: 1px;
      border-color: @outline;
      border-radius: 20px;
      padding: 18px;
    }

    mainbox {
      spacing: 16px;
      children: [ inputbar, listview ];
    }

    inputbar {
      background-color: @surface;
      border: 1px;
      border-color: @outline;
      border-radius: 12px;
      padding: 11px 15px;
      children: [ prompt, entry ];
    }

    prompt {
      text-color: @primary;
      padding: 0 12px 0 0;
    }

    entry {
      placeholder: "Найти обои...";
      placeholder-color: @text-muted;
      cursor: text;
    }

    listview {
      columns: 3;
      lines: 2;
      spacing: 12px;
      fixed-height: true;
      scrollbar: false;
      cycle: true;
    }

    element {
      orientation: vertical;
      background-color: @surface;
      border: 2px;
      border-color: transparent;
      border-radius: 14px;
      padding: 9px;
      spacing: 8px;
    }

    element selected.normal {
      background-color: @surface-high;
      border-color: @primary;
      text-color: @primary;
    }

    element-icon {
      size: 250px;
      border-radius: 10px;
      horizontal-align: 0.5;
    }

    element-text {
      text-color: inherit;
      horizontal-align: 0.5;
      vertical-align: 0.5;
      highlight: bold;
    }
  '';
}
