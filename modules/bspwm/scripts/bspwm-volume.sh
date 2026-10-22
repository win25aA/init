# bspwm-volume up|down|mute — громкость + OSD-уведомление

sink=@DEFAULT_AUDIO_SINK@
case "${1:-}" in
  up)   wpctl set-mute "$sink" 0; wpctl set-volume -l 1.0 "$sink" 5%+ ;;
  down) wpctl set-volume "$sink" 5%- ;;
  mute) wpctl set-mute "$sink" toggle ;;
  *) echo "usage: bspwm-volume up|down|mute" >&2; exit 1 ;;
esac

out=$(wpctl get-volume "$sink")
vol=$(awk '{ printf "%d", $2 * 100 }' <<<"$out")
if grep -q MUTED <<<"$out"; then
  icon=audio-volume-muted; text="Без звука"
else
  if   [ "$vol" -ge 70 ]; then icon=audio-volume-high
  elif [ "$vol" -ge 30 ]; then icon=audio-volume-medium
  else icon=audio-volume-low; fi
  text="Громкость: $vol%"
fi

notify-send -a osd -u low -t 1200 -i "$icon" \
  -h string:x-dunst-stack-tag:volume -h "int:value:$vol" "$text"
