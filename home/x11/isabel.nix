# Тема Isabel из gh0stzk/dotfiles для bspwm, переделанная под NixOS (декларативно).
# Откуда берётся: flake-вход `gh0stzk` (github:gh0stzk/dotfiles) — темы rofi, анимации picom,
# шрифты и скрипты меню. Обои свои, цвета из них делает matugen.
#
#   Панель (polybar)  → ./isabel/polybar.ini (цвета, модули, шрифты — всё там)
#   Лаунчер и меню    → темы rofi из gh0stzk + цвета matugen
#   Анимации и тени   → picom из gh0stzk как есть
#   Уведомления       → dunst из gh0stzk + цвета matugen
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
    @import "${config.xdg.configHome}/rofi/isabel-shared-matugen.rasi"
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
    cfg="${config.xdg.configHome}/polybar/matugen-config.ini"
    [ -f "$cfg" ] || cfg="${config.xdg.configHome}/polybar/config.ini"
    for m in $(polybar --list-monitors | cut -d: -f1); do
      MONITOR=$m setsid -f polybar -q isa-bar -c "$cfg" >/dev/null 2>&1
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
  # Запасные цвета нужны до первой генерации или если обои отсутствуют.
  # Эти файлы обычные, не симлинки: matugen может их перезаписать.
  {
    home.activation.isabelColorFallback = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "${config.xdg.configHome}/rofi" "${config.xdg.configHome}/polybar" \
        "${config.xdg.configHome}/dunst/dunstrc.d" "${config.xdg.configHome}/i3lock"
      if [ ! -f "${config.xdg.configHome}/rofi/isabel-shared-matugen.rasi" ]; then
        printf '* {}\n' > "${config.xdg.configHome}/rofi/isabel-shared-matugen.rasi"
      fi
      if [ ! -f "${config.xdg.configHome}/rofi/matugen-colors.rasi" ]; then
        cat > "${config.xdg.configHome}/rofi/matugen-colors.rasi" <<'RASI'
      * { bg: #14171c; bg-alt: #181b21; bg-sel: #8677cf; fg: #abb2bf; grey: #5c6370; accent: #8677cf; active: #81ae5f; urgent: #e06c75; }
      RASI
      fi
    '';
  }

  # ════════════════════════════════════════════════════════════
  # Matugen: сохраняем геометрию Isabel, заменяя только цвета.
  {
    xdg.configFile."matugen/config.toml".text = ''
      [templates.isabel_polybar]
      input_path = "~/.config/matugen/isabel-polybar.ini"
      output_path = "~/.config/polybar/matugen-config.ini"

      [templates.isabel_rofi]
      input_path = "~/.config/matugen/isabel-rofi.rasi"
      output_path = "~/.config/rofi/isabel-shared-matugen.rasi"

      [templates.rofi]
      input_path = "~/.config/matugen/rofi-colors.rasi"
      output_path = "~/.config/rofi/matugen-colors.rasi"

      [templates.dunst]
      input_path = "~/.config/matugen/dunst-colors.conf"
      output_path = "~/.config/dunst/dunstrc.d/zzz-matugen.conf"

      [templates.i3lock]
      input_path = "~/.config/matugen/i3lock-colors.sh"
      output_path = "~/.config/i3lock/matugen-colors.sh"
    '';

    xdg.configFile."matugen/isabel-polybar.ini".text = lib.replaceStrings
      [ "bg = #14171c" "fg = #abb2bf" "red = #be5046" "green = #81ae5f" "blue = #4889be" "magenta = #7560d3" "grey = #6b7280" "indigo = #5f6fbd" ]
      [ "bg = {{colors.surface.default.hex}}" "fg = {{colors.on_surface.default.hex}}" "red = {{colors.error.default.hex}}" "green = {{colors.secondary.default.hex}}" "blue = {{colors.primary.default.hex}}" "magenta = {{colors.tertiary.default.hex}}" "grey = {{colors.outline.default.hex}}" "indigo = {{colors.primary.default.hex}}" ]
      (builtins.readFile ./isabel/polybar.ini);

    xdg.configFile."matugen/isabel-rofi.rasi".text = ''
      * {
        background: {{colors.surface.default.hex}};
        bg-alt: {{colors.surface_container.default.hex}};
        background-alt: {{colors.surface_container.default.hex}};
        foreground: {{colors.on_surface.default.hex}};
        selected: {{colors.primary.default.hex}};
        active: {{colors.secondary.default.hex}};
        urgent: {{colors.error.default.hex}};
      }
    '';
    xdg.configFile."matugen/rofi-colors.rasi".text = ''
      * {
        bg: {{colors.surface.default.hex}};
        bg-alt: {{colors.surface_container.default.hex}};
        bg-sel: {{colors.surface_container_highest.default.hex}};
        fg: {{colors.on_surface.default.hex}};
        grey: {{colors.outline.default.hex}};
        accent: {{colors.primary.default.hex}};
        active: {{colors.secondary.default.hex}};
        urgent: {{colors.error.default.hex}};
      }
    '';
    xdg.configFile."matugen/dunst-colors.conf".text = ''
      [global]
      frame_color = "{{colors.primary.default.hex}}"
      separator_color = "{{colors.outline_variant.default.hex}}"
      [urgency_low]
      background = "{{colors.surface.default.hex}}"
      foreground = "{{colors.on_surface.default.hex}}"
      highlight = "{{colors.primary.default.hex}}"
      [urgency_normal]
      background = "{{colors.surface.default.hex}}"
      foreground = "{{colors.on_surface.default.hex}}"
      highlight = "{{colors.primary.default.hex}}"
      [urgency_critical]
      background = "{{colors.surface.default.hex}}"
      foreground = "{{colors.on_surface.default.hex}}"
      frame_color = "{{colors.error.default.hex}}"
      highlight = "{{colors.error.default.hex}}"
    '';
    xdg.configFile."matugen/i3lock-colors.sh".text = ''
      LOCK_BG="{{colors.surface.default.hex_stripped}}"
      LOCK_FG="{{colors.on_surface.default.hex_stripped}}"
      LOCK_DIM="{{colors.on_surface_variant.default.hex_stripped}}"
      LOCK_RING="{{colors.surface_container_high.default.hex_stripped}}"
      LOCK_ACCENT="{{colors.primary.default.hex_stripped}}"
      LOCK_VERIFY="{{colors.secondary.default.hex_stripped}}"
      LOCK_WRONG="{{colors.error.default.hex_stripped}}"
    '';
  }

  # ════════════════════════════════════════════════════════════
  # dunst: оформление Isabel; цвета переопределяет zzz-matugen.conf.
  {
    xdg.configFile."dunst/dunstrc".text = lib.replaceStrings
      [ "/usr/bin/dmenu -p dunst:" "/usr/bin/xdg-open" ]
      [ "${pkgs.rofi}/bin/rofi -dmenu -p dunst:" "${pkgs.xdg-utils}/bin/xdg-open" ]
      (builtins.readFile "${inputs.gh0stzk}/config/dunst/dunstrc");

    # Цвета в zzz-matugen.conf имеют приоритет над этим оформлением.
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
      format = "<span size='xx-large' font_desc='Cantarell 9' weight='bold'>%s</span>\n%b"

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
