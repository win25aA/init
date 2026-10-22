# Меню сессии (как session-панель noctalia)

lock=$'\uf023  Заблокировать'
suspend=$'\uf236  Сон'
logout=$'\uf2f5  Выйти'
reboot=$'\uf2f9  Перезагрузка'
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
