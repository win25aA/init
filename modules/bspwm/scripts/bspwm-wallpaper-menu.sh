# Выбор обоев из /etc/nixos/wallpapers (аналог панели обоев noctalia)

dir=${WALLPAPER_DIR:-/etc/nixos/wallpapers}
mapfile -t files < <(find "$dir" -maxdepth 1 -type f \
  \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
  ! -name '.*' | sort)
[ ${#files[@]} -eq 0 ] && { notify-send "Обои" "Нет картинок в $dir"; exit 1; }

idx=$(for f in "${files[@]}"; do
        printf '%s\0icon\x1f%s\n' "$(basename "$f")" "$f"
      done | rofi -dmenu -i -show-icons -format i -p "Обои" -theme-str '
        window   { width: 900px; }
        listview { columns: 4; lines: 2; flow: horizontal; }
        element  { orientation: vertical; padding: 10px; }
        element-icon { size: 160px; }
        element-text { horizontal-align: 0.5; }')

[ -n "$idx" ] && bspwm-wallpaper "${files[$idx]}"
true
