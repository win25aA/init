{ config, pkgs, lib, inputs, ... }:

let
  # xorg.* постепенно переезжает в корень nixpkgs
  xpkg = name: pkgs.${name} or pkgs.xorg.${name};

  # на X11 у NVIDIA выходы называются иначе, чем под Wayland — ищем по разрешению
  monitors = pkgs.writeShellScriptBin "bspwm-monitors" ''
    # Мониторы. На X11 у NVIDIA имена выходов другие, чем под Wayland
    # (DVI-D-0 / HDMI-0 вместо DVI-D-1 / HDMI-A-1), поэтому ищем их по разрешению.
    # Можно задать вручную: BSPWM_MAIN=DVI-D-0 BSPWM_SECOND=HDMI-0

    outputs=$(xrandr --query | awk '
      / connected/ { o = $1; next }
      o && /^ +[0-9]+x[0-9]+/ && /\+/ { print o, $1; o = "" }')

    main=''${BSPWM_MAIN:-$(awk '$2 == "1440x900" { print $1; exit }' <<<"$outputs")}
    second=''${BSPWM_SECOND:-$(awk '$2 == "1024x768" { print $1; exit }' <<<"$outputs")}

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
  '';

  # обои + перегенерация цветов matugen (как хук noctalia)
  wallpaper = pkgs.writeShellScriptBin "bspwm-wallpaper" ''
    # bspwm-wallpaper <картинка> [--no-reload]
    # Ставит обои и перегенерирует ВСЕ цвета через matugen (как хук noctalia).

    wall=''${1:-}
    if [ ! -f "$wall" ]; then
      echo "usage: bspwm-wallpaper <image> [--no-reload]" >&2
      exit 1
    fi
    wall=$(realpath "$wall")

    cache="''${XDG_CACHE_HOME:-$HOME/.cache}"
    mkdir -p "$cache" "${config.xdg.configHome}"/{polybar,rofi,dunst/dunstrc.d,picom,i3lock}
    printf '%s\n' "$wall" > "$cache/bspwm-wallpaper"

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

  autostart = pkgs.writeShellScriptBin "bspwm-autostart" ''
    # Автозапуск. Безопасно перезапускать (super + alt + r): ничего не дублируется.

    cache="''${XDG_CACHE_HOME:-$HOME/.cache}/bspwm-wallpaper"
    default_wall="/etc/nixos/wallpapers/wallpaperflare.com_wallpaper.jpg"
    wall=$(cat "$cache" 2>/dev/null || true)
    [ -f "$wall" ] || wall="$default_wall"

    run() { pgrep -x "$1" >/dev/null || setsid -f "$@" >/dev/null 2>&1; }

    xsetroot -cursor_name left_ptr

    # цвета от matugen: при первом запуске генерируем, дальше просто ставим обои
    if [ ! -f "${config.xdg.configHome}/polybar/matugen-colors.ini" ]; then
      ${wallpaper}/bin/bspwm-wallpaper "$wall" --no-reload
    else
      feh --no-fehbg --bg-fill "$wall"
    fi

    pgrep -x picom >/dev/null || picom --daemon
    run dunst
    run clipmenud
    pgrep -f polkit-gnome-authentication-agent-1 >/dev/null || setsid -f ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 >/dev/null 2>&1

    polybar-launch

    command -v AmneziaVPN >/dev/null && run AmneziaVPN
    true
  '';

  lock = pkgs.writeShellScriptBin "bspwm-lock" ''
    # Локскрин (замена локскрина noctalia): размытый скрин + цвета matugen

    pgrep -x 'i3lock(-color)?' >/dev/null && exit 0

    # shellcheck disable=SC1091
    [ -f "${config.xdg.configHome}/i3lock/matugen-colors.sh" ] && . "${config.xdg.configHome}/i3lock/matugen-colors.sh"

    img="''${XDG_RUNTIME_DIR:-/tmp}/bspwm-lock.png"
    maim -u "$img" && magick "$img" -scale 10% -blur 0x2 -resize 1000% "$img" || img=""

    paused=$(dunstctl is-paused 2>/dev/null)
    dunstctl set-paused true 2>/dev/null
    playerctl pause 2>/dev/null

    i3lock-color -n -e ''${img:+-i "$img"} \
      --clock --indicator --radius 110 --ring-width 8 \
      --time-str="%H:%M" --date-str="%A, %d %B" \
      --time-font="Inconsolata SemiCondensed" --date-font="Inconsolata SemiCondensed" \
      --layout-font="Inconsolata SemiCondensed" --verif-font="Inconsolata SemiCondensed" \
      --wrong-font="Inconsolata SemiCondensed" \
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
    # bspwm-screenshot full|region — сохраняет в ~/Pictures/Screenshots и копирует в буфер

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
    # bspwm-volume up|down|mute — громкость + OSD-уведомление

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
  home.packages = with pkgs; [
    monitors wallpaper autostart lock screenshot volume
    feh matugen maim xclip imagemagick i3lock-color
    playerctl wireplumber libnotify clipmenu
    (xpkg "xrandr") (xpkg "xsetroot")
  ];

  xsession.windowManager.bspwm = {
    enable = true;
    extraConfigEarly = "${monitors}/bin/bspwm-monitors";

    settings = {
      border_width = 0;              # как в Hyprland: рамок нет
      window_gap = 10;               # gaps_in 5 + 5 / gaps_out 10
      split_ratio = 0.5;
      automatic_scheme = "longest_side";   # похоже на dwindle
      initial_polarity = "second_child";
      removal_adjustment = true;
      borderless_monocle = true;
      gapless_monocle = false;
      single_monocle = false;
      focus_follows_pointer = true;
      pointer_follows_focus = false;
      pointer_follows_monitor = true;
      # Super + ЛКМ — двигать, Super + ПКМ — менять размер
      pointer_modifier = "mod4";
      pointer_action1 = "move";
      pointer_action2 = "resize_side";
      pointer_action3 = "resize_corner";
    };

    rules = {
      "Pavucontrol" = { state = "floating"; center = true; rectangle = "820x520+0+0"; };
      "pavucontrol" = { state = "floating"; center = true; rectangle = "820x520+0+0"; };
      "org.pulseaudio.pavucontrol" = { state = "floating"; center = true; rectangle = "820x520+0+0"; };
      "AmneziaVPN" = { state = "floating"; center = true; };
      "Thunar:*:File Operation Progress" = { state = "floating"; };
    };

    extraConfig = "${autostart}/bin/bspwm-autostart &";
  };
}
