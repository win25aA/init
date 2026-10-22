# bspwm-wallpaper <картинка> [--no-reload]
# Ставит обои и перегенерирует ВСЕ цвета через matugen (как хук noctalia).

wall=${1:-}
if [ ! -f "$wall" ]; then
  echo "usage: bspwm-wallpaper <image> [--no-reload]" >&2
  exit 1
fi
wall=$(realpath "$wall")

cache="${XDG_CACHE_HOME:-$HOME/.cache}"
mkdir -p "$cache" "@CONFIG@/bspwm"
printf '%s\n' "$wall" > "$cache/bspwm-wallpaper"

feh --no-fehbg --bg-fill "$wall"
matugen image "$wall" --type scheme-content --source-color-index 0

[ "${2:-}" = "--no-reload" ] && exit 0

polybar-msg cmd restart >/dev/null 2>&1 || polybar-launch
dunstctl reload 2>/dev/null || { pkill -x dunst; setsid -f dunst >/dev/null 2>&1; }
pkill -USR1 -x picom 2>/dev/null
pkill -USR1 -x kitty 2>/dev/null
notify-send -i "$wall" "Обои" "Цвета обновлены"
true
