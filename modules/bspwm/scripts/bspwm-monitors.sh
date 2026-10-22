# Мониторы. На X11 у NVIDIA имена выходов другие, чем под Wayland
# (DVI-D-0 / HDMI-0 вместо DVI-D-1 / HDMI-A-1), поэтому ищем их по разрешению.
# Можно задать вручную: BSPWM_MAIN=DVI-D-0 BSPWM_SECOND=HDMI-0

outputs=$(xrandr --query | awk '
  / connected/ { o = $1; next }
  o && /^ +[0-9]+x[0-9]+/ && /\+/ { print o, $1; o = "" }')

main=${BSPWM_MAIN:-$(awk '$2 == "1440x900" { print $1; exit }' <<<"$outputs")}
second=${BSPWM_SECOND:-$(awk '$2 == "1024x768" { print $1; exit }' <<<"$outputs")}

if [ -n "$main" ] && [ -n "$second" ] && [ "$main" != "$second" ]; then
  xrandr --output "$main" --primary --mode 1440x900 --rate 75 --pos 0x0 --rotate normal \
         --output "$second" --mode 1024x768 --rate 70 --pos 1440x355 --rotate normal \
    || xrandr --output "$main" --primary --mode 1440x900 --pos 0x0 \
              --output "$second" --mode 1024x768 --pos 1440x355
  bspc monitor "$main" -d 1 2 3 4 5
  bspc monitor "$second" -d 6 7 8 9 10
  # bspwm сам сортирует мониторы по порядку xrandr — фиксируем основной первым
  bspc wm -O "$main" "$second"
else
  # один монитор (или не нашли нужные) — все 10 столов на первом
  first=$(bspc query -M --names | head -n1)
  bspc monitor "$first" -d 1 2 3 4 5 6 7 8 9 10
fi
