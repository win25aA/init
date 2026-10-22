# Текущий трек для polybar: «Исполнитель - Название» (без кнопок управления)

playerctl --follow metadata --format '{{status}}|||{{artist}}|||{{title}}' 2>/dev/null |
while IFS= read -r line; do
  status=${line%%|||*}; rest=${line#*|||}
  artist=${rest%%|||*}; title=${rest#*|||}
  if [ -z "$title" ] || [ "$status" = "Stopped" ] || [ "$line" = "$rest" ]; then
    echo ""
  elif [ -n "$artist" ]; then
    printf '%s - %s\n' "$artist" "$title"
  else
    printf '%s\n' "$title"
  fi | sed 's/%{/%%{/g'
done

# плееров нет — пустой модуль (polybar перезапустит скрипт сам)
echo ""
sleep 5
