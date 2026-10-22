# Запуск polybar: isa-bar на основном мониторе (с треем), isa-bar-secondary на остальных

pkill -x polybar
while pgrep -x polybar >/dev/null; do sleep 0.1; done

primary=$(xrandr --query | awk '/ connected primary/ { print $1; exit }')
mapfile -t mons < <(polybar --list-monitors | cut -d: -f1)
[ -z "$primary" ] && primary=${mons[0]}

for m in "${mons[@]}"; do
  if [ "$m" = "$primary" ]; then
    MONITOR=$m setsid -f polybar -q isa-bar >/dev/null 2>&1
  else
    MONITOR=$m setsid -f polybar -q isa-bar-secondary >/dev/null 2>&1
  fi
done
