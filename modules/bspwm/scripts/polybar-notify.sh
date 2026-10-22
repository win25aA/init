# Колокольчик уведомлений: обычный / перечёркнутый в режиме «Не беспокоить»

if [ "$(dunstctl is-paused 2>/dev/null)" = "true" ]; then
  echo $'\uf1f6'
else
  n=$(dunstctl count history 2>/dev/null || echo 0)
  if [ "${n:-0}" -gt 0 ]; then echo $'\uf0f3'" $n"; else echo $'\uf0f3'; fi
fi
