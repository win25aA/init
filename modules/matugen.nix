{ config, pkgs, lib, inputs, ... }:

let
  # Начальные значения нужны до первого выбора обоев. Все шаблоны ниже — здесь же.
  initialColors = {
    surface = "#212529"; surface_container = "#272b2f"; on_surface = "#f8f9fa";
    primary = "#dee2e6"; on_primary = "#212529";
    secondary = "#adb5bd"; tertiary = "#e9ecef";
    error = "#dee2e6"; outline = "#8c8c8c";
    outline_variant = "#495057"; on_surface_variant = "#ced4da";
  };
  templateNames = [ "silvia-colors.ini" "polybar-colors.ini" "rofi-colors.rasi" "dunst-colors.conf" "bspwm-colors.sh" "lock-colors.sh" ];
  initialTemplate = name:
    let
      names = builtins.attrNames initialColors;
      tokens = (map (key: "{{colors.${key}.default.hex}}") names)
        ++ (map (key: "{{colors.${key}.default.hex_stripped}}") names);
      values = (map (key: initialColors.${key}) names)
        ++ (map (key: lib.removePrefix "#" initialColors.${key}) names);
    in lib.replaceStrings tokens values config.xdg.configFile."matugen/${name}".text;
  reloadColors = pkgs.writeShellScriptBin "bspwm-reload-colors" ''
    export PATH=${lib.makeBinPath [ pkgs.bspwm pkgs.dunst pkgs.polybar pkgs.systemd pkgs.procps pkgs.coreutils ]}:$PATH
    # Matugen используется также в Noctalia: не трогаем Wayland-сессии.
    [ "$XDG_SESSION_TYPE" = x11 ] && [ "$XDG_CURRENT_DESKTOP" = bspwm ] || exit 0
    bspc query -M >/dev/null 2>&1 || exit 0
    state="$HOME/.local/state/bspwm"
    [ ! -r "$state/bspwm-colors.sh" ] || . "$state/bspwm-colors.sh"
    if [ -r "$state/dunst-colors.conf" ]; then
      cat ${config.xdg.configHome}/dunst/dunstrc "$state/dunst-colors.conf" > "$state/dunstrc.new"
      mv "$state/dunstrc.new" "$state/dunstrc"
      if systemctl --user is-active --quiet bspwm-dunst.service; then
        dunstctl reload "$state/dunstrc" || true
      fi
    fi
    if systemctl --user is-active --quiet bspwm-polybar.service; then
      polybar-msg cmd restart >/dev/null 2>&1 || true
    fi
    pkill -USR1 -u "$(id -u)" -x kitty 2>/dev/null || true
  '';
in
{
  xdg.configFile."matugen/config.toml".text = ''
    [config]
    image_mode = "dark"
    # Брать самый доминантный цвет без интерактивного выбора.
    # В matugen 4.1.0 ключ в конфиге ещё не поддержан (только CLI-флаг
    # --source-color-index, он передаётся в хуке noctalia), но оставляем
    # на будущее — после обновления matugen флаг станет не нужен.
    source_color_index = 0

    [templates.polybar_silvia]
    index = 99
    input_path = "~/.config/matugen/silvia-colors.ini"
    output_path = "~/.local/state/bspwm/silvia-colors.ini"

    [templates.x11_0]
    index = 100
    input_path = "~/.config/matugen/polybar-colors.ini"
    output_path = "~/.local/state/bspwm/polybar-colors.ini"

    [templates.x11_1]
    index = 101
    input_path = "~/.config/matugen/rofi-colors.rasi"
    output_path = "~/.local/state/bspwm/rofi-colors.rasi"

    [templates.x11_2]
    index = 102
    input_path = "~/.config/matugen/dunst-colors.conf"
    output_path = "~/.local/state/bspwm/dunst-colors.conf"

    [templates.x11_3]
    index = 103
    input_path = "~/.config/matugen/bspwm-colors.sh"
    output_path = "~/.local/state/bspwm/bspwm-colors.sh"

    [templates.x11_4]
    index = 104
    input_path = "~/.config/matugen/lock-colors.sh"
    output_path = "~/.local/state/bspwm/lock-colors.sh"
    post_hook = "${reloadColors}/bin/bspwm-reload-colors"

    [templates.btop]
    input_path = "~/.config/matugen/btop-colors.theme"
    output_path = "~/.config/btop/themes/matugen.theme"

    [templates.kitty]
    input_path = "/home/winarowk/.config/matugen/kitty.conf"
    output_path = "~/.config/kitty/matugen-colors.conf"

    [templates.fish]
    input_path = "~/.config/matugen/fish-colors.fish"
    output_path = "~/.config/fish/matugen-colors.fish"

    [templates.gtk3]
    input_path = "~/.config/matugen/gtk-colors.css"
    output_path = "~/.config/gtk-3.0/matugen-colors.css"

    [templates.gtk4]
    input_path = "~/.config/matugen/gtk-colors.css"
    output_path = "~/.config/gtk-4.0/matugen-colors.css"

    [templates.mpv]
    input_path = "~/.config/matugen/mpv-colors.conf"
    output_path = "~/.config/mpv/matugen-colors.conf"

  '';


  xdg.configFile."matugen/kitty.conf".text = ''
    foreground            {{colors.on_surface.default.hex}}
    selection_foreground  {{colors.surface.default.hex}}
    selection_background  {{colors.primary.default.hex}}
    cursor                {{colors.primary.default.hex}}
    cursor_text_color     {{colors.surface.default.hex}}

    color0  {{colors.surface.default.hex}}
    color1  {{colors.error.default.hex}}
    color2  {{colors.primary.default.hex}}
    color3  {{colors.secondary.default.hex}}
    color4  {{colors.tertiary.default.hex}}
    color5  {{colors.primary.default.hex}}
    color6  {{colors.secondary.default.hex}}
    color7  {{colors.on_surface.default.hex}}

    color8  {{colors.surface_variant.default.hex}}
    color9  {{colors.error.default.hex}}
    color10 {{colors.primary.default.hex}}
    color11 {{colors.secondary.default.hex}}
    color12 {{colors.tertiary.default.hex}}
    color13 {{colors.primary.default.hex}}
    color14 {{colors.secondary.default.hex}}
    color15 {{colors.on_surface.default.hex}}
  '';

  xdg.configFile."matugen/btop-colors.theme".text = ''
    theme[main_bg]="{{colors.surface.default.hex}}"
    theme[main_fg]="{{colors.on_surface.default.hex}}"
    theme[title]="{{colors.primary.default.hex}}"
    theme[hi_fg]="{{colors.secondary.default.hex}}"
    theme[selected_bg]="{{colors.surface_variant.default.hex}}"
    theme[selected_fg]="{{colors.on_surface.default.hex}}"
    theme[inactive_fg]="{{colors.outline.default.hex}}"
    theme[graph_text]="{{colors.on_surface_variant.default.hex}}"
    theme[meter_bg]="{{colors.surface_container_highest.default.hex}}"
    theme[proc_misc]="{{colors.primary.default.hex}}"
    theme[cpu_box]="{{colors.primary.default.hex}}"
    theme[mem_box]="{{colors.secondary.default.hex}}"
    theme[net_box]="{{colors.tertiary.default.hex}}"
    theme[proc_box]="{{colors.error.default.hex}}"
    theme[div_line]="{{colors.outline_variant.default.hex}}"
    theme[temp_start]="{{colors.primary.default.hex}}"
    theme[temp_mid]="{{colors.secondary.default.hex}}"
    theme[temp_end]="{{colors.error.default.hex}}"
    theme[cpu_start]="{{colors.primary.default.hex}}"
    theme[cpu_mid]="{{colors.secondary.default.hex}}"
    theme[cpu_end]="{{colors.error.default.hex}}"
    theme[free_start]="{{colors.primary.default.hex}}"
    theme[free_mid]="{{colors.secondary.default.hex}}"
    theme[free_end]="{{colors.error.default.hex}}"
    theme[cached_start]="{{colors.tertiary.default.hex}}"
    theme[cached_mid]="{{colors.secondary.default.hex}}"
    theme[cached_end]="{{colors.primary.default.hex}}"
    theme[available_start]="{{colors.primary.default.hex}}"
    theme[available_mid]="{{colors.secondary.default.hex}}"
    theme[available_end]="{{colors.error.default.hex}}"
    theme[used_start]="{{colors.primary.default.hex}}"
    theme[used_mid]="{{colors.secondary.default.hex}}"
    theme[used_end]="{{colors.error.default.hex}}"
    theme[download_start]="{{colors.primary.default.hex}}"
    theme[download_mid]="{{colors.secondary.default.hex}}"
    theme[download_end]="{{colors.error.default.hex}}"
    theme[upload_start]="{{colors.primary.default.hex}}"
    theme[upload_mid]="{{colors.secondary.default.hex}}"
    theme[upload_end]="{{colors.error.default.hex}}"
    theme[process_start]="{{colors.primary.default.hex}}"
    theme[process_mid]="{{colors.secondary.default.hex}}"
    theme[process_end]="{{colors.error.default.hex}}"
  '';

  xdg.configFile."matugen/fish-colors.fish".text = ''
    set -U fish_color_normal {{colors.on_surface.default.hex_stripped}}
    set -U fish_color_command {{colors.tertiary.default.hex_stripped}}
    set -U fish_color_param {{colors.on_surface_variant.default.hex_stripped}}
    set -U fish_color_quote {{colors.secondary.default.hex_stripped}}
    set -U fish_color_escape {{colors.secondary.default.hex_stripped}}
    set -U fish_color_autosuggestion {{colors.outline.default.hex_stripped}}
    set -U fish_color_error {{colors.error.default.hex_stripped}}
    set -U fish_color_comment {{colors.surface_variant.default.hex_stripped}}
    set -U fish_color_selection --background={{colors.surface_container_highest.default.hex_stripped}}
    set -U fish_color_search_match --background={{colors.surface_container_highest.default.hex_stripped}}
  '';

  xdg.configFile."matugen/gtk-colors.css".text = ''
    @define-color accent_color {{colors.primary.default.hex}};
    @define-color accent_bg_color {{colors.primary.default.hex}};
    @define-color accent_fg_color {{colors.on_primary.default.hex}};

    @define-color destructive_color {{colors.error.default.hex}};
    @define-color destructive_bg_color {{colors.error_container.default.hex}};
    @define-color destructive_fg_color {{colors.on_error_container.default.hex}};

    @define-color success_color {{colors.tertiary.default.hex}};
    @define-color success_bg_color {{colors.tertiary_container.default.hex}};
    @define-color success_fg_color {{colors.on_tertiary_container.default.hex}};

    @define-color warning_color {{colors.secondary.default.hex}};
    @define-color warning_bg_color {{colors.secondary_container.default.hex}};
    @define-color warning_fg_color {{colors.on_secondary_container.default.hex}};

    @define-color error_color {{colors.error.default.hex}};
    @define-color error_bg_color {{colors.error_container.default.hex}};
    @define-color error_fg_color {{colors.on_error_container.default.hex}};

    @define-color window_bg_color {{colors.surface.default.hex}};
    @define-color window_fg_color {{colors.on_surface.default.hex}};

    @define-color view_bg_color {{colors.surface.default.hex}};
    @define-color view_fg_color {{colors.on_surface.default.hex}};

    @define-color headerbar_bg_color {{colors.surface_container.default.hex}};
    @define-color headerbar_fg_color {{colors.on_surface.default.hex}};
    @define-color headerbar_border_color {{colors.outline_variant.default.hex}};
    @define-color headerbar_backdrop_color @window_bg_color;

    @define-color card_bg_color {{colors.surface_container.default.hex}};
    @define-color card_fg_color {{colors.on_surface.default.hex}};

    @define-color dialog_bg_color {{colors.surface_container_high.default.hex}};
    @define-color dialog_fg_color {{colors.on_surface.default.hex}};

    @define-color popover_bg_color {{colors.surface_container.default.hex}};
    @define-color popover_fg_color {{colors.on_surface.default.hex}};

    @define-color sidebar_bg_color {{colors.surface_container.default.hex}};
    @define-color sidebar_fg_color {{colors.on_surface.default.hex}};
    @define-color sidebar_backdrop_color @window_bg_color;

    @define-color thumbnail_bg_color {{colors.surface_container.default.hex}};
    @define-color thumbnail_fg_color {{colors.on_surface.default.hex}};
  '';


  xdg.configFile."matugen/mpv-colors.conf".text = ''
    osd-color = "{{colors.primary.default.hex}}"
    osd-border-color = "{{colors.surface.default.hex}}"
  '';

  xdg.configFile."mpv/mpv.conf".text = ''
    include=~~/matugen-colors.conf
  '';

  # X11: шаблоны цветов живут в этом модуле, как и остальные шаблоны Matugen.
  xdg.configFile."matugen/polybar-colors.ini".text = ''
    [color]
    bg = #FA{{colors.surface.default.hex_stripped}}
    bg-alt = {{colors.outline_variant.default.hex}}
    fg = {{colors.on_surface.default.hex}}
    red = {{colors.primary.default.hex}}
    pink = {{colors.tertiary.default.hex}}
    purple = {{colors.on_surface_variant.default.hex}}
    blue = {{colors.outline_variant.default.hex}}
    cyan = {{colors.secondary.default.hex}}
    teal = {{colors.tertiary.default.hex}}
    green = {{colors.secondary.default.hex}}
    lime = {{colors.tertiary.default.hex}}
    yellow = {{colors.tertiary.default.hex}}
    amber = {{colors.secondary.default.hex}}
    orange = {{colors.error.default.hex}}
    brown = {{colors.secondary.default.hex}}
    grey = {{colors.outline.default.hex}}
    indigo = {{colors.tertiary.default.hex}}
    blue-gray = {{colors.outline.default.hex}}
  '';

  # Silvia: raised surface, readable inactive workspaces and tonal module accents.
  # The original Gruvbox layout stays; the wallpaper, not fixed Gruvbox RGB, sets hues.
  xdg.configFile."matugen/silvia-colors.ini".text = ''
    [color]
    bg = {{colors.surface_container.default.hex}}
    bg-alt = {{colors.outline_variant.default.hex}}
    fg = {{colors.on_surface.default.hex}}
    trans = #00000000
    white = {{colors.on_surface.default.hex}}
    black = {{colors.surface.default.hex}}
    red = {{colors.error.default.hex}}
    pink = {{colors.tertiary.default.hex}}
    purple = {{colors.tertiary.default.hex}}
    blue = {{colors.primary.default.hex}}
    cyan = {{colors.secondary.default.hex}}
    teal = {{colors.secondary.default.hex}}
    green = {{colors.primary.default.hex}}
    lime = {{colors.primary.default.hex}}
    yellow = {{colors.tertiary.default.hex}}
    amber = {{colors.tertiary.default.hex}}
    orange = {{colors.error.default.hex}}
    brown = {{colors.secondary.default.hex}}
    grey = {{colors.outline.default.hex}}
    indigo = {{colors.secondary.default.hex}}
    blue-gray = {{colors.on_surface_variant.default.hex}}
  '';

  xdg.configFile."matugen/rofi-colors.rasi".text = ''
    * {
      background: {{colors.surface.default.hex}};
      foreground: {{colors.on_surface.default.hex}};
      selected: {{colors.primary.default.hex}};
      on-selected: {{colors.on_primary.default.hex}};
      outline: {{colors.outline_variant.default.hex}};
    }
  '';

  xdg.configFile."matugen/dunst-colors.conf".text = ''
    [urgency_low]
      timeout = 4
      background = "{{colors.surface.default.hex}}"
      foreground = "{{colors.on_surface.default.hex}}"
      frame_color = "{{colors.outline_variant.default.hex}}"
    
    [urgency_normal]
      timeout = 7
      background = "{{colors.surface.default.hex}}"
      foreground = "{{colors.on_surface.default.hex}}"
      frame_color = "{{colors.primary.default.hex}}"
    
    [urgency_critical]
      timeout = 0
      background = "{{colors.surface.default.hex}}"
      foreground = "{{colors.on_surface.default.hex}}"
      frame_color = "{{colors.error.default.hex}}"
    
  '';

  xdg.configFile."matugen/bspwm-colors.sh".text = ''
    bspc config normal_border_color "{{colors.outline_variant.default.hex}}"
    bspc config active_border_color "{{colors.secondary.default.hex}}"
    bspc config focused_border_color "{{colors.primary.default.hex}}"
    bspc config presel_feedback_color "{{colors.primary.default.hex}}"
  '';

  xdg.configFile."matugen/lock-colors.sh".text = ''
    bg="{{colors.surface.default.hex_stripped}}"
    fg="{{colors.on_surface.default.hex_stripped}}"
    primary="{{colors.primary.default.hex_stripped}}"
    muted="{{colors.on_surface_variant.default.hex_stripped}}"
    error="{{colors.error.default.hex_stripped}}"
  '';

  home.packages = [ reloadColors ];
  home.activation.matugenX11Defaults = lib.hm.dag.entryAfter [ "writeBoundary" ] (''
    $DRY_RUN_CMD mkdir -p "$HOME/.local/state/bspwm"
  '' + lib.concatMapStringsSep "\n" (name: ''
    if [ ! -e "$HOME/.local/state/bspwm/${name}" ]; then
      $DRY_RUN_CMD install -m 600 ${pkgs.writeText "initial-${name}" (initialTemplate name)} "$HOME/.local/state/bspwm/${name}"
    fi
  '') templateNames);
}
