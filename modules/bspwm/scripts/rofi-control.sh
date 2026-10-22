# Центр управления (замена control-center noctalia):
# ночной свет, буфер обмена, уведомления, обои, звук, скриншот

if pgrep -x gammastep >/dev/null; then night=$'\uf186  Ночной свет: вкл'; else night=$'\uf185  Ночной свет: выкл'; fi
if [ "$(dunstctl is-paused 2>/dev/null)" = "true" ]; then dnd=$'\uf1f6  Не беспокоить: вкл'; else dnd=$'\uf0f3  Не беспокоить: выкл'; fi
clip=$'\uf328  Буфер обмена'
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
  "$walls") bspwm-wallpaper-menu ;;
  "$sound") pavucontrol & ;;
  "$shot")  sleep 0.3; bspwm-screenshot region ;;
  "$power") rofi-power ;;
esac
true
