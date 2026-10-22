# Локскрин (замена локскрина noctalia): размытый скрин + цвета matugen

pgrep -x 'i3lock(-color)?' >/dev/null && exit 0

LOCK_BG=1a1a1a LOCK_FG=e6e1e5 LOCK_DIM=c9c5d0 LOCK_RING=2b2930
LOCK_ACCENT=d0bcff LOCK_VERIFY=ccc2dc LOCK_WRONG=f2b8b5
# shellcheck disable=SC1091
[ -f "@CONFIG@/bspwm/lock-colors.sh" ] && . "@CONFIG@/bspwm/lock-colors.sh"

img="${XDG_RUNTIME_DIR:-/tmp}/bspwm-lock.png"
maim -u "$img" && magick "$img" -scale 10% -blur 0x2 -resize 1000% "$img" \
  || magick -size 1920x1080 "xc:#$LOCK_BG" "$img"

paused=$(dunstctl is-paused 2>/dev/null)
dunstctl set-paused true 2>/dev/null
playerctl pause 2>/dev/null

i3lock-color -n -e -i "$img" \
  --clock --indicator --radius 110 --ring-width 8 \
  --time-str="%H:%M" --date-str="%A, %d %B" \
  --time-font="Inconsolata SemiCondensed" --date-font="Inconsolata SemiCondensed" \
  --layout-font="Inconsolata SemiCondensed" --verif-font="Inconsolata SemiCondensed" \
  --wrong-font="Inconsolata SemiCondensed" \
  --time-size=48 --date-size=18 --layout-size=14 \
  --time-color="${LOCK_FG}ff" --date-color="${LOCK_DIM}ff" --layout-color="${LOCK_DIM}ff" \
  --inside-color="${LOCK_BG}cc" --ring-color="${LOCK_RING}ff" \
  --insidever-color="${LOCK_BG}cc" --ringver-color="${LOCK_VERIFY}ff" \
  --insidewrong-color="${LOCK_BG}cc" --ringwrong-color="${LOCK_WRONG}ff" \
  --line-uses-inside --separator-color="00000000" \
  --keyhl-color="${LOCK_ACCENT}ff" --bshl-color="${LOCK_WRONG}ff" \
  --verif-color="${LOCK_FG}ff" --wrong-color="${LOCK_WRONG}ff" \
  --verif-text="…" --wrong-text="Неверно" --noinput-text="Пусто" \
  --keylayout 1 --pass-media-keys --pass-volume-keys

rm -f "$img"
[ "$paused" = "true" ] || dunstctl set-paused false 2>/dev/null
true
