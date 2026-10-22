# bspwm-screenshot full|region — сохраняет в ~/Pictures/Screenshots и копирует в буфер

dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$dir"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"

case "${1:-full}" in
  region) maim -u -s "$file" || exit 0 ;;
  *)      maim -u "$file" ;;
esac

xclip -selection clipboard -t image/png -i "$file"
notify-send -i "$file" "Скриншот" "Сохранён и скопирован в буфер"
