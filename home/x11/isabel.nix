# Тема Isabel из gh0stzk/dotfiles для bspwm, переделанная под NixOS (декларативно).
# Откуда берётся: flake-вход `gh0stzk` (github:gh0stzk/dotfiles) — темы rofi, анимации picom,
# шрифты, обои и скрипты меню. Тут только подключение и мои правки.
#
#   Панель (polybar)  → ./isabel/polybar.ini (цвета, модули, шрифты — всё там)
#   Лаунчер и меню    → темы rofi из gh0stzk + цвета Isabel (блок «rofi» ниже)
#   Анимации и тени   → picom из gh0stzk как есть
#   Уведомления       → dunst из gh0stzk + цвета Isabel
{ config, lib, pkgs, inputs, ... }:

let
  bsp = "${inputs.gh0stzk}/config/bspwm";

  # Шрифты из gh0stzk: Material Design Icons Desktop, Font Awesome 6 и др. (нужны панели).
  gh0stzkFonts = pkgs.runCommand "gh0stzk-fonts" { } ''
    mkdir -p $out/share/fonts/gh0stzk
    find ${inputs.gh0stzk}/misc/fonts -type f \( -iname '*.ttf' -o -iname '*.otf' \) \
      -exec cp {} $out/share/fonts/gh0stzk/ \;
  '';

  # Темы rofi из gh0stzk, в shared.rasi — цвета и шрифт Isabel.
  rofiThemes = pkgs.runCommand "isabel-rofi-themes" { } ''
    cp -r ${bsp}/config/rofi-themes $out
    chmod -R u+w $out
    cat > $out/shared.rasi <<'RASI'
    * {
        font: "Terminess Nerd Font Mono Bold 10";
        background: #14171c;
        bg-alt: #181b21;
        background-alt: #14171cE0;
        foreground: #abb2bf;
        selected: #8677cf;
        active: #81ae5f;
        urgent: #e06c75;
    }
    RASI
  '';

  # Скрипты меню из gh0stzk (как есть, только пути поправлены под NixOS):
  #   RofiLauncher — лаунчер, PowerMenu — выключение, ScreenShoTer — скриншоты,
  #   Colorpicker — пипетка, rofi-bluetooth — Bluetooth.
  gh0stzkScripts = pkgs.runCommand "isabel-scripts" { } ''
    mkdir -p $out/bin
    for s in RofiLauncher PowerMenu ScreenShoTer Colorpicker rofi-bluetooth bluetooth-polybar.sh; do
      cp ${bsp}/bin/$s $out/bin/$s
    done
    chmod u+w,+x $out/bin/*
    substituteInPlace $out/bin/PowerMenu \
      --replace-fail '"Lock") ScreenLocker' '"Lock") bspwm-lock'
    substituteInPlace $out/bin/ScreenShoTer \
      --replace-fail /usr/share/sounds ${pkgs.sound-theme-freedesktop}/share/sounds \
      --replace-fail '$HOME/.config/bspwm/config/assets/screenshot.png' '${bsp}/config/assets/screenshot.png'
    patchShebangs $out/bin
  '';

  # Запуск панели на всех мониторах.
  polybarLaunch = pkgs.writeShellScriptBin "polybar-launch" ''
    pkill -x polybar
    while pgrep -x polybar >/dev/null; do sleep 0.1; done
    for m in $(polybar --list-monitors | cut -d: -f1); do
      MONITOR=$m setsid -f polybar -q isa-bar -c ${config.xdg.configHome}/polybar/config.ini >/dev/null 2>&1
    done
  '';

  # Выпадающий терминал (scratchpad): Super+Alt+Enter — показать/спрятать.
  scratchpad = pkgs.writeShellScriptBin "bspwm-scratchpad" ''
    id=$(xdo id -N scratchpad 2>/dev/null | head -n1)
    if [ -z "$id" ]; then
      setsid -f kitty --class scratchpad >/dev/null 2>&1
    else
      bspc node "$id" --flag hidden && bspc node -f "$id"
    fi
  '';

  # Шапка лаунчера (картинка сверху) — кусок текущих обоев.
  rofiHeader = pkgs.writeShellScriptBin "rofi-header" ''
    [ -f "$1" ] || exit 0
    mkdir -p "$HOME/.cache"
    magick "$1" -strip -resize 30% -gravity center -crop 760x196+0+0 +repage \
      -quality 65 "$HOME/.cache/rofi_header.webp"
  '';
in
lib.mkMerge [
  # ════════════════════════════════════════════════════════════
  # Программы и шрифты для темы.
  {
    home.packages = with pkgs; [
      gh0stzkScripts polybarLaunch scratchpad rofiHeader
      polybarFull rofi picom dunst libnotify
      playerctl pavucontrol bluez bc xcolor xdo xclip maim jq imagemagick xdg-user-dirs procps
      gh0stzkFonts inconsolata nerd-fonts.terminess-ttf nerd-fonts.jetbrains-mono papirus-icon-theme
    ];
    fonts.fontconfig.enable = true;
  }

  # ════════════════════════════════════════════════════════════
  # Файлы gh0stzk по тем же путям, что у него (скрипты ищут их там).
  {
    xdg.configFile."bspwm/config/rofi-themes".source = rofiThemes;
    xdg.configFile."bspwm/config/picom".source = "${bsp}/config/picom";
    xdg.configFile."bspwm/config/assets".source = "${bsp}/config/assets";
  }

  # ════════════════════════════════════════════════════════════
  # Панель polybar (бар bar09 из Isabel).
  {
    xdg.configFile."polybar/config.ini".source = ./isabel/polybar.ini;
  }

  # ════════════════════════════════════════════════════════════
  # rofi: обычные меню (Управление, Уведомления и т.д.) — тоже в цветах Isabel.
  {
    xdg.configFile."rofi/isabel-colors.rasi".text = ''
      * {
          bg:     #14171c;
          bg-alt: #181b21;
          bg-sel: #8677cf;
          fg:     #abb2bf;
          grey:   #5c6370;
          accent: #8677cf;
          active: #81ae5f;
          urgent: #e06c75;
      }
    '';
  }

  # ════════════════════════════════════════════════════════════
  # dunst: уведомления. Основа из gh0stzk, цвета Isabel.
  {
    xdg.configFile."dunst/dunstrc".text = lib.replaceStrings
      [ "/usr/bin/dmenu -p dunst:" "/usr/bin/xdg-open" ]
      [ "${pkgs.rofi}/bin/rofi -dmenu -p dunst:" "${pkgs.xdg-utils}/bin/xdg-open" ]
      (builtins.readFile "${inputs.gh0stzk}/config/dunst/dunstrc");

    # «zz-» — чтобы этот файл читался последним и его цвета были главными.
    xdg.configFile."dunst/dunstrc.d/zz-isabel.conf".text = ''
      [global]
      origin = top-center
      offset = (0, 10)
      transparency = 0
      corner_radius = 6
      frame_width = 0
      frame_color = "#8677cf"
      font = Inconsolata Semi Condensed Bold 9
      icon_theme = "Papirus-Dark, Adwaita"
      format = "<span size='xx-large' font_desc='Cantarell 9' weight='bold' foreground='#4889be'>%s</span>\n%b"

      [urgency_low]
      timeout = 3
      background = "#14171c"
      foreground = "#81ae5f"

      [urgency_normal]
      timeout = 5
      background = "#14171c"
      foreground = "#abb2bf"

      [urgency_critical]
      timeout = 0
      background = "#14171c"
      foreground = "#be5046"
    '';
  }
]
