{ config, pkgs, inputs, ... }:

let
  wallpaper = pkgs.writeShellScriptBin "wallpaper" ''
    WALL_DIR="/etc/nixos/wallpapers"
    CACHE="$HOME/.cache/current_wallpaper"

    # ждём, пока поднимется демон awww
    for i in $(seq 1 20); do
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

    [ -z "$WALL" ] && exit 1

    ${pkgs.awww}/bin/awww img "$WALL" \
      --transition-type grow \
      --transition-pos center \
      --transition-duration 1.2 \
      --transition-fps 75

    echo "$WALL" > "$CACHE"

    # генерим новую тему matugen из обоев
    # (matugen требует tty, поэтому оборачиваем в псевдо-терминал через script)
    ${pkgs.util-linux}/bin/script -qec "${pkgs.matugen}/bin/matugen image \"$WALL\"" /dev/null >> "$HOME/.cache/wallpaper.log" 2>&1

    # перезапускаем waybar, чтобы тема применилась
    if systemctl --user is-active --quiet waybar.service; then
      systemctl --user restart waybar.service
    else
      pkill waybar 2>/dev/null
      sleep 0.3
      hyprctl dispatch exec waybar >/dev/null 2>&1 || waybar & disown
    fi
  '';
in
{
  home.packages = [
    pkgs.awww
    wallpaper
  ];
}
