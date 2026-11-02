# bspwm: скрипты (мониторы, обои, автозапуск, блокировка, скриншоты, громкость).
# Это не модуль, а функция: её импортирует ./bspwm.nix и сам кладёт скрипты в PATH.
{ pkgs, config, inputs }:

let
  monitors = pkgs.writeShellScriptBin "bspwm-monitors" ''

    connected=$(xrandr --query | awk '/ connected/ { print $1 }')
    second=''${BSPWM_SECOND:-$(grep -m1 '^HDMI' <<<"$connected")}
    main=''${BSPWM_MAIN:-$(grep -v -x -F "''${second:-none}" <<<"$connected" | head -n1)}

    set_mode() {
      local out=$1 w=$2 h=$3 hz=$4 pos=$5; shift 5
      xrandr --output "$out" --mode "''${w}x''${h}" --rate "$hz" --pos "$pos" --rotate normal "$@" && return
      local line name
      line=$(cvt "$w" "$h" "$hz" | sed -n 's/^Modeline //p')
      name=$(awk '{ print $1 }' <<<"$line" | tr -d '"')
      xrandr --newmode $(tr -d '"' <<<"$line") 2>/dev/null
      xrandr --addmode "$out" "$name" 2>/dev/null
      xrandr --output "$out" --mode "$name" --pos "$pos" --rotate normal "$@" \
        || xrandr --output "$out" --mode "''${w}x''${h}" --pos "$pos" --rotate normal "$@"
    }

    xrdb -merge <<<"Xft.dpi: 96"

    if [ -n "$main" ] && [ -n "$second" ]; then
      set_mode "$main"   1440 900 74.98 0x0 --primary
      set_mode "$second" 1024 768 70.07 1440x355
      xrandr --dpi 96
      sleep 0.3
      bspc monitor "$main" -d 1 2 3 4 5
      bspc monitor "$second" -d 6 7 8 9 10
      bspc wm -O "$main" "$second"
      for m in $(bspc query -M --names); do
        [ "$m" = "$main" ] || [ "$m" = "$second" ] || bspc monitor "$m" -r
      done
    else
      xrandr --dpi 96
      first=$(bspc query -M --names | head -n1)
      bspc monitor "$first" -d 1 2 3 4 5 6 7 8 9 10
    fi
  '';

  wallpaper = pkgs.writeShellScriptBin "bspwm-wallpaper" ''

    wall=''${1:-}
    if [ ! -f "$wall" ]; then
      echo "usage: bspwm-wallpaper <image> [--no-reload]" >&2
      exit 1
    fi
    wall=$(realpath "$wall")

    cache="''${XDG_CACHE_HOME:-$HOME/.cache}"
    mkdir -p "$cache"
    printf '%s\n' "$wall" > "$cache/bspwm-wallpaper"

    feh --no-fehbg --bg-fill "$wall"
    rofi-header "$wall"
    if ! matugen image "$wall" --type scheme-content --source-color-index 0; then
      notify-send "Обои" "Не удалось обновить цвета matugen"
      exit 1
    fi

    [ "''${2:-}" = "--no-reload" ] && exit 0

    polybar-launch
    pkill -x dunst 2>/dev/null || true
    setsid -f dunst >/dev/null 2>&1
    pkill -USR1 -x kitty 2>/dev/null || true
    notify-send -i "$wall" "Обои" "Цвета обновлены"
    true
  '';

  autostart = pkgs.writeShellScriptBin "bspwm-autostart" ''

    cache="''${XDG_CACHE_HOME:-$HOME/.cache}/bspwm-wallpaper"
    dir="''${WALLPAPER_DIR:-/etc/nixos/wallpapers}"
    default_wall="$dir/astolfo-wallpapers.jpg"
    wall=$(cat "$cache" 2>/dev/null || true)
    # Не восстанавливаем старые обои Isabel из кэша.
    wall_dir=$(realpath "$dir" 2>/dev/null || true)
    case "$wall" in "$wall_dir"/*) ;; *) wall="" ;; esac
    [ -f "$wall" ] || wall="$default_wall"
    if [ ! -f "$wall" ] && [ -d "$dir" ]; then
      wall=$(find "$dir" -maxdepth 1 -type f         \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \)         ! -name '.*' | sort | head -n1)
    fi

    run() { pgrep -x "$1" >/dev/null || setsid -f "$@" >/dev/null 2>&1; }

    xsetroot -cursor_name left_ptr

    if [ -f "$wall" ]; then
      ${wallpaper}/bin/bspwm-wallpaper "$wall" --no-reload
    fi

    pgrep -x picom >/dev/null || picom --daemon --config "${config.xdg.configHome}/bspwm/config/picom/picom.conf"
    run dunst
    run clipmenud
    pgrep -f polkit-gnome-authentication-agent-1 >/dev/null || setsid -f ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 >/dev/null 2>&1

    polybar-launch

    command -v AmneziaVPN >/dev/null && run AmneziaVPN
    true
  '';

  lock = pkgs.writeShellScriptBin "bspwm-lock" ''

    pgrep -x 'i3lock(-color)?' >/dev/null && exit 0

    # Запасные цвета; если matugen уже работал, используем его цвета.
    LOCK_BG=14171c LOCK_FG=abb2bf LOCK_DIM=5c6370 LOCK_RING=181b21
    LOCK_VERIFY=81ae5f LOCK_WRONG=be5046 LOCK_ACCENT=8677cf
    [ ! -f "${config.xdg.configHome}/i3lock/matugen-colors.sh" ] || . "${config.xdg.configHome}/i3lock/matugen-colors.sh"

    img="''${XDG_RUNTIME_DIR:-/tmp}/bspwm-lock.png"
    maim -u "$img" && magick "$img" -scale 10% -blur 0x2 -resize 1000% "$img" || img=""

    paused=$(dunstctl is-paused 2>/dev/null)
    dunstctl set-paused true 2>/dev/null
    playerctl pause 2>/dev/null

    i3lock-color -n -e ''${img:+-i "$img"} \
      --clock --indicator --radius 110 --ring-width 8 \
      --time-str="%H:%M" --date-str="%A, %d %B" \
      --time-font="JetBrainsMono Nerd Font" --date-font="JetBrainsMono Nerd Font" \
      --layout-font="JetBrainsMono Nerd Font" --verif-font="JetBrainsMono Nerd Font" \
      --wrong-font="JetBrainsMono Nerd Font" \
      --time-size=48 --date-size=18 --layout-size=14 \
      --time-color="''${LOCK_FG}ff" --date-color="''${LOCK_DIM}ff" --layout-color="''${LOCK_DIM}ff" \
      --inside-color="''${LOCK_BG}cc" --ring-color="''${LOCK_RING}ff" \
      --insidever-color="''${LOCK_BG}cc" --ringver-color="''${LOCK_VERIFY}ff" \
      --insidewrong-color="''${LOCK_BG}cc" --ringwrong-color="''${LOCK_WRONG}ff" \
      --line-uses-inside --separator-color="00000000" \
      --keyhl-color="''${LOCK_ACCENT}ff" --bshl-color="''${LOCK_WRONG}ff" \
      --verif-color="''${LOCK_FG}ff" --wrong-color="''${LOCK_WRONG}ff" \
      --verif-text="…" --wrong-text="Неверно" --noinput-text="Пусто" \
      --keylayout 1 --pass-media-keys --pass-volume-keys

    rm -f "$img"
    [ "$paused" = "true" ] || dunstctl set-paused false 2>/dev/null
    true
  '';

  screenshot = pkgs.writeShellScriptBin "bspwm-screenshot" ''

    dir="''${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
    mkdir -p "$dir"
    file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"

    case "''${1:-full}" in
      region) maim -u -s "$file" || exit 0 ;;
      *)      maim -u "$file" ;;
    esac

    xclip -selection clipboard -t image/png -i "$file"
    notify-send -i "$file" "Скриншот" "Сохранён и скопирован в буфер"
  '';

  volume = pkgs.writeShellScriptBin "bspwm-volume" ''

    sink=@DEFAULT_AUDIO_SINK@
    case "''${1:-}" in
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
  '';
in
{
  inherit monitors wallpaper autostart lock screenshot volume;
}
