{ config, pkgs, lib, inputs, ... }:

# rofi: лаунчер + меню, заменяющие панели noctalia
let
  power = pkgs.writeShellScriptBin "rofi-power" ''
    # Меню сессии (как session-панель noctalia)

    lock=$'\uf023  Заблокировать'
    suspend=$'\uf236  Сон'
    logout=$'\U000f0343  Выйти'
    reboot=$'\U000f0709  Перезагрузка'
    shutdown=$'\uf011  Выключить'

    confirm() {
      [ "$(printf 'Да\nНет\n' | rofi -dmenu -i -p "$1?" -theme-str 'window { width: 260px; } listview { lines: 2; }')" = "Да" ]
    }

    choice=$(printf '%s\n' "$lock" "$suspend" "$logout" "$reboot" "$shutdown" |
      rofi -dmenu -i -p "Сессия" -theme-str 'window { width: 320px; } listview { lines: 5; }')

    case "$choice" in
      "$lock")     bspwm-lock ;;
      "$suspend")  bspwm-lock & sleep 1; systemctl suspend ;;
      "$logout")   confirm "Выйти" && bspc quit ;;
      "$reboot")   confirm "Перезагрузить" && systemctl reboot ;;
      "$shutdown") confirm "Выключить" && systemctl poweroff ;;
    esac
    true
  '';

  control = pkgs.writeShellScriptBin "rofi-control" ''
    # Центр управления (замена control-center noctalia):
    # ночной свет, буфер обмена, уведомления, обои, звук, скриншот

    if pgrep -x gammastep >/dev/null; then night=$'\uf186  Ночной свет: вкл'; else night=$'\uf185  Ночной свет: выкл'; fi
    if [ "$(dunstctl is-paused 2>/dev/null)" = "true" ]; then dnd=$'\uf1f6  Не беспокоить: вкл'; else dnd=$'\uf0f3  Не беспокоить: выкл'; fi
    clip=$'\U000f0147  Буфер обмена'
    hist=$'\uf0e0  История уведомлений'
    walls=$'\uf03e  Обои'
    sound=$'\uf028  Звук'
    shot=$'\uf030  Скриншот области'
    power=$'\uf011  Сессия'

    choice=$(printf '%s\n' "$night" "$dnd" "$clip" "$hist" "$walls" "$sound" "$shot" "$power" |
      rofi -dmenu -i -p "Управление" -theme-str 'window { width: 380px; } listview { lines: 8; }')

    case "$choice" in
      "$night")
        if pgrep -x gammastep >/dev/null; then pkill -x gammastep
        else setsid -f gammastep -l 55.9122:49.3128 -t 6500:4000 >/dev/null 2>&1; fi ;;
      "$dnd")   dunstctl set-paused toggle ;;
      "$clip")  CM_LAUNCHER=rofi clipmenu -p "Буфер" ;;
      "$hist")  rofi-notifications ;;
      "$walls") rofi-wallpaper ;;
      "$sound") pavucontrol & ;;
      "$shot")  sleep 0.3; bspwm-screenshot region ;;
      "$power") rofi-power ;;
    esac
    true
  '';

  notifications = pkgs.writeShellScriptBin "rofi-notifications" ''
    # История уведомлений dunst в rofi: Enter — показать снова, первая строка — очистить

    clear=$'\uf1f8  Очистить историю'
    json=$(dunstctl history 2>/dev/null) || exit 0

    mapfile -t ids < <(jq -r '.data[0][] | .id.data' <<<"$json")
    mapfile -t rows < <(jq -r '.data[0][] |
      "\(.appname.data): \(.summary.data)" +
      (if (.body.data | length) > 0 then " — " + (.body.data | gsub("\n"; " ")) else "" end)' <<<"$json")

    idx=$( { echo "$clear"; [ ''${#rows[@]} -gt 0 ] && printf '%s\n' "''${rows[@]}"; } |
      rofi -dmenu -i -format i -p "Уведомления" -theme-str 'window { width: 640px; }')

    [ -z "$idx" ] && exit 0
    if [ "$idx" -eq 0 ]; then
      dunstctl history-clear
    else
      dunstctl history-pop "''${ids[$((idx - 1))]}"
    fi
  '';

  wallpapers = pkgs.writeShellScriptBin "rofi-wallpaper" ''
    # Выбор обоев из /etc/nixos/wallpapers (аналог панели обоев noctalia)

    dir=''${WALLPAPER_DIR:-/etc/nixos/wallpapers}
    mapfile -t files < <(find "$dir" -maxdepth 1 -type f \
      \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
      ! -name '.*' | sort)
    [ ''${#files[@]} -eq 0 ] && { notify-send "Обои" "Нет картинок в $dir"; exit 1; }

    idx=$(for f in "''${files[@]}"; do
            printf '%s\0icon\x1f%s\n' "$(basename "$f")" "$f"
          done | rofi -dmenu -i -show-icons -format i -p "Обои" -theme-str '
            window   { width: 900px; }
            listview { columns: 4; lines: 2; flow: horizontal; }
            element  { orientation: vertical; padding: 10px; }
            element-icon { size: 160px; }
            element-text { horizontal-align: 0.5; }')

    [ -n "$idx" ] && bspwm-wallpaper "''${files[$idx]}"
    true
  '';
in

{
  home.packages = with pkgs; [
    rofi jq gammastep clipmenu pavucontrol
    power control notifications wallpapers
  ];

  xdg.configFile."rofi/config.rasi".text = ''
    /* rofi — лаунчер и меню. Цвета: matugen-colors.rasi от matugen */
    configuration {
        dpi: 96;
        modi: "drun";
        show-icons: true;
        icon-theme: "Papirus-Dark";
        display-drun: "";
        drun-display-format: "{name}";
        hover-select: true;
        me-select-entry: "";
        me-accept-entry: "MousePrimary";
        kb-cancel: "Escape,Super+space";
    }

    @import "${config.xdg.configHome}/rofi/matugen-colors.rasi"

    * {
        font: "JetBrainsMono Nerd Font Propo Bold 10";
        background-color: transparent;
        text-color: @fg;
        margin: 0;
        padding: 0;
        spacing: 0;
    }

    window {
        location: center;
        width: 480px;
        border: 0;
        border-radius: 6px;
        background-color: @bg;
        padding: 12px;
    }

    mainbox {
        spacing: 10px;
        children: [ inputbar, message, listview ];
    }

    inputbar {
        background-color: @bg-alt;
        border-radius: 6px;
        padding: 8px 12px;
        spacing: 10px;
        children: [ prompt, entry ];
    }

    prompt { text-color: @accent; }

    entry {
        placeholder: "Поиск…";
        placeholder-color: @grey;
        cursor: text;
    }

    message {
        background-color: @bg-alt;
        border-radius: 6px;
        padding: 8px 12px;
    }

    textbox { text-color: @grey; }

    listview {
        lines: 8;
        columns: 1;
        dynamic: true;
        fixed-height: false;
        scrollbar: false;
        cycle: true;
        spacing: 4px;
    }

    element {
        padding: 7px 10px;
        border-radius: 6px;
        spacing: 10px;
    }

    element normal.normal, element alternate.normal { background-color: transparent; text-color: @fg; }
    element selected.normal { background-color: @bg-sel; text-color: @accent; }
    element normal.active, element alternate.active { background-color: transparent; text-color: @active; }
    element selected.active { background-color: @bg-sel; text-color: @active; }
    element normal.urgent, element alternate.urgent { background-color: transparent; text-color: @urgent; }
    element selected.urgent { background-color: @bg-sel; text-color: @urgent; }

    element-icon {
        size: 22px;
        vertical-align: 0.5;
    }

    element-text {
        vertical-align: 0.5;
        text-color: inherit;
    }
  '';
}
