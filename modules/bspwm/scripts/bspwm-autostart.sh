# Автозапуск. Безопасно перезапускать (super + alt + r): ничего не дублируется.

cache="${XDG_CACHE_HOME:-$HOME/.cache}/bspwm-wallpaper"
default_wall="/etc/nixos/wallpapers/wallpaperflare.com_wallpaper.jpg"
wall=$(cat "$cache" 2>/dev/null || true)
[ -f "$wall" ] || wall="$default_wall"

run() { pgrep -x "$1" >/dev/null || setsid -f "$@" >/dev/null 2>&1; }

xsetroot -cursor_name left_ptr

# цвета от matugen: при первом запуске генерируем, дальше просто ставим обои
if [ ! -f "@CONFIG@/polybar/colors.ini" ] || [ ! -f "@CONFIG@/dunst/dunstrc" ]; then
  bspwm-wallpaper "$wall" --no-reload
else
  feh --no-fehbg --bg-fill "$wall"
fi

pgrep -x picom >/dev/null || picom --daemon
run dunst
run clipmenud
pgrep -f polkit-gnome-authentication-agent-1 >/dev/null || setsid -f "$POLKIT_AGENT" >/dev/null 2>&1

polybar-launch

command -v AmneziaVPN >/dev/null && run AmneziaVPN
true
