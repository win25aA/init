{ config, pkgs, lib, inputs, ... }:

# Polybar из риса Isabel — gh0stzk/dotfiles (bars/bar09)
let
  launch = pkgs.writeShellScriptBin "polybar-launch" ''
    # Запуск polybar: isa-bar на основном мониторе (с треем), isa-bar-secondary на остальных

    pkill -x polybar
    while pgrep -x polybar >/dev/null; do sleep 0.1; done

    primary=$(xrandr --query | awk '/ connected primary/ { print $1; exit }')
    mapfile -t mons < <(polybar --list-monitors | cut -d: -f1)
    [ -z "$primary" ] && primary=''${mons[0]}

    for m in "''${mons[@]}"; do
      if [ "$m" = "$primary" ]; then
        MONITOR=$m setsid -f polybar -q isa-bar >/dev/null 2>&1
      else
        MONITOR=$m setsid -f polybar -q isa-bar-secondary >/dev/null 2>&1
      fi
    done
  '';

  # «Исполнитель - Название», без кнопок управления
  media = pkgs.writeShellScriptBin "polybar-media" ''
    # Текущий трек для polybar: «Исполнитель - Название» (без кнопок управления)

    playerctl --follow metadata --format '{{status}}|||{{artist}}|||{{title}}' 2>/dev/null |
    while IFS= read -r line; do
      status=''${line%%|||*}; rest=''${line#*|||}
      artist=''${rest%%|||*}; title=''${rest#*|||}
      if [ -z "$title" ] || [ "$status" = "Stopped" ] || [ "$line" = "$rest" ]; then
        echo ""
      elif [ -n "$artist" ]; then
        printf '%s - %s\n' "$artist" "$title"
      else
        printf '%s\n' "$title"
      fi | sed 's/%{/%%{/g'
    done

    # плееров нет — пустой модуль (polybar перезапустит скрипт сам)
    echo ""
    sleep 5
  '';

  notify = pkgs.writeShellScriptBin "polybar-notify" ''
    # Колокольчик уведомлений: обычный / перечёркнутый в режиме «Не беспокоить»

    if [ "$(dunstctl is-paused 2>/dev/null)" = "true" ]; then
      echo "%{T4}"$'\U000f009b'"%{T-}"
    else
      n=$(dunstctl count history 2>/dev/null || echo 0)
      if [ "''${n:-0}" -gt 0 ]; then echo "%{T4}"$'\U000f009a'"%{T-} $n"; else echo "%{T4}"$'\U000f009a'"%{T-}"; fi
    fi
  '';
in

{
  home.packages = with pkgs; [ polybarFull playerctl dunst launch media notify ];
  fonts.fontconfig.enable = true;

  xdg.configFile."polybar/config.ini".text = ''
    ; Polybar из риса Isabel — gh0stzk/dotfiles (bars/bar09), адаптировано под NixOS.
    ; Оригинал: https://github.com/gh0stzk/dotfiles
    ; Цвета берутся из matugen-colors.ini, который генерирует matugen.

    [global/wm]
    margin-bottom = 0
    margin-top = 0

    include-file = ${config.xdg.configHome}/polybar/matugen-colors.ini
    include-file = ${config.xdg.configHome}/polybar/modules.ini

    [bar/isa-bar]
    monitor = ''${env:MONITOR:}
    monitor-strict = false
    override-redirect = false

    bottom = true
    fixed-center = false

    width = 100%
    height = 40

    offset-x = 0
    offset-y = 0

    background = ''${color.bg}
    foreground = ''${color.fg}

    radius = 0

    line-size = 2
    line-color = ''${color.blue}

    border-size = 0
    border-color = ''${color.bg}

    padding-left = 3
    padding-right = 3

    module-margin-left = 1
    module-margin-right = 1

    ; один шрифт на всё: кириллица + все иконки. Вариант Propo — у иконок
    ; реальная ширина, поэтому они не наезжают на соседние символы
    font-0 = "JetBrainsMono Nerd Font Propo:style=Bold:size=10;3"
    ; лаунчер NixOS
    font-1 = "JetBrainsMono Nerd Font Propo:size=15;4"
    ; иконки рабочих столов
    font-2 = "JetBrainsMono Nerd Font Propo:size=13;4"
    ; иконки модулей — чуть крупнее текста и по центру строки
    font-3 = "JetBrainsMono Nerd Font Propo:size=12;4"

    modules-left = launcher sep2 bspwm sep2 mplayer
    modules-center = title
    modules-right = filesystem sep cpu_bar sep memory_bar sep pulseaudio sep2 tray sep notify sep control sep date sep power

    separator =
    dim-value = 1.0

    wm-restack = bspwm
    enable-struts = true
    enable-ipc = true

    cursor-click = pointer
    cursor-scroll =

    ; второй монитор — то же самое, только без трея (трей может быть один)
    ; второй монитор узкий (1024) — без трея, трека и диска
    [bar/isa-bar-secondary]
    inherit = bar/isa-bar
    modules-left = launcher sep2 bspwm
    modules-right = cpu_bar sep memory_bar sep pulseaudio sep2 notify sep date sep power

    [settings]
    screenchange-reload = false

    compositing-background = source
    compositing-foreground = over
    compositing-overline = over
    compositing-underline = over
    compositing-border = over

    pseudo-transparency = false
  '';

  xdg.configFile."polybar/modules.ini".text = ''
    ;  Модули из Isabel (gh0stzk/dotfiles, bars/bar09/modules.ini).
    ;  Убрано: погода, карточка пользователя, кнопки mpd, сеть, обновления,
    ;  батарея, bluetooth, пипетка, переключатель раскладок bspwm.
    ;  Добавлено из noctalia: трек плеера, уведомления, меню управления.

    [module/date]
    type = internal/date

    interval = 1.0

    time = %H:%M
    time-alt = %H:%M
    format-foreground = ''${color.fg}
    date-alt = "%a, %d %b %Y  "

    format = <label>
    format-prefix-foreground = ''${color.blue}

    label = "%date%%time%"

    ######################################################

    [module/filesystem]
    type = internal/fs

    mount-0 = /

    interval = 60
    fixed-values = true

    format-mounted = <label-mounted>
    format-mounted-prefix = "󰋊 "
    format-mounted-prefix-font = 4
    format-mounted-prefix-foreground = ''${color.blue}

    format-unmounted = <label-unmounted>
    format-unmounted-prefix = "󰋊 "
    format-unmounted-prefix-font = 4

    label-mounted = "%used% "
    label-mounted-foreground = ''${color.grey}
    label-unmounted = %mountpoint%: not mounted

    ######################################################

    [module/pulseaudio]
    type = internal/pulseaudio
    use-ui-max = true
    interval = 5

    format-volume = <ramp-volume><label-volume>
    format-volume-prefix = ""

    label-volume = " %percentage%%"
    label-volume-foreground = ''${color.grey}

    format-muted = <label-muted>
    format-muted-prefix = "󰖁 "
    format-muted-prefix-font = 4
    label-muted = "Muted"
    label-muted-foreground = ''${color.red}

    ramp-volume-0 = 󰕿
    ramp-volume-1 = 󰖀
    ramp-volume-2 = 󰖀
    ramp-volume-3 = 󰕾
    ramp-volume-4 = 󰕾
    ramp-volume-font = 4

    click-right = pavucontrol

    ######################################################

    [module/bspwm]
    type = internal/bspwm

    enable-click = true
    enable-scroll = true
    reverse-scroll = true
    pin-workspaces = true
    occupied-scroll = false

    format = <label-state>
    format-font = 3

    label-focused = 󰮯
    label-focused-padding = 1
    label-focused-foreground = ''${color.fg}
    label-focused-font = 3

    label-occupied = 󰊠
    label-occupied-padding = 1
    label-occupied-foreground = ''${color.fg}
    label-occupied-font = 3

    label-urgent = 󰊠
    label-urgent-padding = 1
    label-urgent-foreground = ''${color.red}
    label-urgent-font = 3

    label-empty = 󰑊
    label-empty-padding = 1
    label-empty-foreground = ''${color.grey}
    label-empty-font = 3

    ######################################################

    [module/title]
    type = internal/xwindow

    format = <label>
    format-prefix = "󱂬 "
    format-prefix-font = 4
    format-prefix-foreground = ''${color.magenta}

    label = %title%
    label-maxlen = 30

    label-empty = "NixOS"
    label-empty-foreground = ''${color.grey}

    ######################################################

    [module/launcher]
    type = custom/text
    label = 󱄅
    label-font = 2
    label-foreground = ''${color.fg}

    click-left = rofi -show drun

    ######################################################

    [module/sep]
    type = custom/text
    label = " "
    label-foreground = ''${color.bg}

    ######################################################

    [module/sep2]
    type = custom/text
    label = " 󰇙 "
    label-foreground = ''${color.indigo}

    ######################################################

    [module/cpu_bar]
    type = internal/cpu

    interval = 0.5
    format = <label>
    format-prefix = "󰻠 "
    format-prefix-font = 4

    label = "%percentage%% "
    label-foreground = ''${color.grey}

    ######################################################

    [module/memory_bar]
    type = internal/memory

    interval = 3

    format = <label>
    format-prefix = "󰍛 "
    format-prefix-font = 4

    label = "%used% "
    label-foreground = ''${color.grey}

    ######################################################

    ; иконка ноты из Isabel + «Исполнитель - Трек» текущего плеера (без кнопок)
    [module/mplayer]
    type = custom/script
    exec = polybar-media
    tail = true

    format = <label>
    format-prefix = "󰎇 "
    format-prefix-font = 4
    format-prefix-foreground = ''${color.green}

    label = %output%
    label-maxlen = 40
    label-foreground = ''${color.fg}

    ######################################################

    [module/power]
    type = custom/text
    label = "󰐥"
    label-font = 4
    label-foreground = ''${color.red}

    click-left = rofi-power

    ######################################################

    ; уведомления (dunst): ЛКМ — «не беспокоить», ПКМ — история
    [module/notify]
    type = custom/script
    exec = polybar-notify
    interval = 2

    format = <label>
    label = "%output%"
    label-foreground = ''${color.yellow}

    click-left = dunstctl set-paused toggle
    click-right = rofi-notifications

    ######################################################

    ; меню управления (вместо control center из noctalia)
    [module/control]
    type = custom/text
    label = "󰘮"
    label-font = 4
    label-foreground = ''${color.blue}

    click-left = rofi-control

    #####################################################

    [module/tray]
    type = internal/tray

    format = <tray>
    format-background = ''${color.bg}
    tray-background = ''${color.bg}
    tray-foreground = ''${color.fg}
    tray-spacing = 10px
    tray-padding = 0px
    tray-size = 40%
  '';
}
