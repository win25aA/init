# Общие X11-утилиты: обои, блокировка, снимки и громкость.
{ pkgs, config, ... }:

let
  xpkg = name: pkgs.${name} or pkgs.xorg.${name};
  wallpaper = pkgs.writeShellScriptBin "x11-wallpaper" ''

    wall=''${1:-}
    if [ ! -f "$wall" ]; then
      echo "usage: x11-wallpaper <image> [--no-reload]" >&2
      exit 1
    fi
    wall=$(realpath "$wall")

    cache="''${XDG_CACHE_HOME:-$HOME/.cache}"
    mkdir -p "$cache" "${config.xdg.configHome}"/{polybar,rofi,dunst/dunstrc.d,picom,i3lock}
    printf '%s\n' "$wall" > "$cache/x11-wallpaper"

    feh --no-fehbg --bg-fill "$wall"
    matugen image "$wall" --type scheme-content --source-color-index 0

    [ "''${2:-}" = "--no-reload" ] && exit 0

    polybar-msg cmd restart >/dev/null 2>&1 || polybar-launch
    dunstctl reload 2>/dev/null || { pkill -x dunst; setsid -f dunst >/dev/null 2>&1; }
    pkill -USR1 -x picom 2>/dev/null
    pkill -USR1 -x kitty 2>/dev/null
    notify-send -i "$wall" "Обои" "Цвета обновлены"
    true
  '';

  lock = pkgs.writeShellScriptBin "x11-lock" ''

    pgrep -x 'i3lock(-color)?' >/dev/null && exit 0

    [ -f "${config.xdg.configHome}/i3lock/matugen-colors.sh" ] && . "${config.xdg.configHome}/i3lock/matugen-colors.sh"

    img="''${XDG_RUNTIME_DIR:-/tmp}/x11-lock.png"
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

  screenshot = pkgs.writeShellScriptBin "x11-screenshot" ''

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

  volume = pkgs.writeShellScriptBin "x11-volume" ''

    sink=@DEFAULT_AUDIO_SINK@
    case "''${1:-}" in
      up)   wpctl set-mute "$sink" 0; wpctl set-volume -l 1.0 "$sink" 5%+ ;;
      down) wpctl set-volume "$sink" 5%- ;;
      mute) wpctl set-mute "$sink" toggle ;;
      *) echo "usage: x11-volume up|down|mute" >&2; exit 1 ;;
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
  home.packages = with pkgs; [
    wallpaper lock screenshot volume
    feh matugen maim xclip imagemagick i3lock-color
    playerctl wireplumber libnotify clipmenu sxhkd
    (xpkg "xrandr") (xpkg "xsetroot") (xpkg "xrdb") libxcvt
  ];
}
