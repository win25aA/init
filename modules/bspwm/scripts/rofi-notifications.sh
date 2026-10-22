# История уведомлений dunst в rofi: Enter — показать снова, первая строка — очистить

clear=$'\uf1f8  Очистить историю'
json=$(dunstctl history 2>/dev/null) || exit 0

mapfile -t ids < <(jq -r '.data[0][] | .id.data' <<<"$json")
mapfile -t rows < <(jq -r '.data[0][] |
  "\(.appname.data): \(.summary.data)" +
  (if (.body.data | length) > 0 then " — " + (.body.data | gsub("\n"; " ")) else "" end)' <<<"$json")

idx=$( { echo "$clear"; [ ${#rows[@]} -gt 0 ] && printf '%s\n' "${rows[@]}"; } |
  rofi -dmenu -i -format i -p "Уведомления" -theme-str 'window { width: 640px; }')

[ -z "$idx" ] && exit 0
if [ "$idx" -eq 0 ]; then
  dunstctl history-clear
else
  dunstctl history-pop "${ids[$((idx - 1))]}"
fi
