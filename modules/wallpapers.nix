{ config, pkgs, inputs, ... }:

let
  wallpaper = pkgs.writeShellScriptBin "wallpaper" ''
    WALL_DIR="/etc/nixos/wallpapers"
    CACHE="$HOME/.cache/current_wallpaper"
    LOG="$HOME/.cache/wallpaper.log"
    : > "$LOG"

    log() { echo "[wallpaper] $1" >> "$LOG"; }

    # ждём, пока поднимется демон awww
    for i in $(seq 1 40); do
      ${pkgs.awww}/bin/awww query >/dev/null 2>&1 && break
      sleep 0.25
    done

    case "$1" in
      --restore)
        if [ -f "$CACHE" ] && [ -f "$(cat "$CACHE")" ]; then
          WALL="$(cat "$CACHE")"
        else
          WALL="$(find "$WALL_DIR" -type f \( -name '*.jpg' -o -name '*.jpeg' -o -name '*.png' \) | shuf -n 1)"
        fi
        ;;
      "")
        # без аргументов — случайные обои (кроме текущих)
        WALL="$(find "$WALL_DIR" -type f \( -name '*.jpg' -o -name '*.jpeg' -o -name '*.png' \) | grep -vxF "$(cat "$CACHE" 2>/dev/null)" | shuf -n 1)"
        ;;
      *)
        WALL="$1"
        ;;
    esac

    if [ -z "$WALL" ]; then
      log "ERROR: не нашёл обои в $WALL_DIR"
      exit 1
    fi
    log "ставлю обои: $WALL"

    ${pkgs.coreutils}/bin/timeout 15 ${pkgs.awww}/bin/awww img "$WALL" \
      --transition-type grow \
      --transition-pos center \
      --transition-duration 1.2 \
      --transition-fps 75 >> "$LOG" 2>&1 && log "awww: ok" || log "awww: FAIL"

    echo "$WALL" > "$CACHE"

    # генерим тему matugen: сначала обычный запуск,
    # если он падает (напр. 'not a terminal') — повторяем через псевдо-tty
    if ${pkgs.coreutils}/bin/timeout 20 ${pkgs.matugen}/bin/matugen image "$WALL" >> "$LOG" 2>&1; then
      log "matugen: ok"
    elif ${pkgs.coreutils}/bin/timeout 20 ${pkgs.expect}/bin/unbuffer ${pkgs.matugen}/bin/matugen image "$WALL" >> "$LOG" 2>&1; then
      log "matugen: ok (через unbuffer)"
    else
      log "matugen: FAIL — смотри ошибки выше"
    fi

    # перезапускаем waybar В ЛЮБОМ СЛУЧАЕ
    pkill -x waybar 2>/dev/null && log "waybar: убит старый"
    sleep 0.5
    if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
      hyprctl dispatch exec waybar >> "$LOG" 2>&1
      log "waybar: запущен через hyprctl"
    else
      nohup waybar >/dev/null 2>&1 &
      log "waybar: запущен напрямую"
    fi

    log "готово"
  '';
in
{
  home.packages = [
    pkgs.awww
    wallpaper
  ];
}
