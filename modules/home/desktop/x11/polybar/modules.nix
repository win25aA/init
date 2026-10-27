# polybar: модули (часы, звук, воркспейсы, трей и т.д.).
{ ... }:

{
  xdg.configFile."polybar/modules.ini".text = ''

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

    [module/filesystem]
    type = internal/fs

    mount-0 = /

    interval = 60
    fixed-values = true

    format-mounted = <label-mounted>
    format-mounted-prefix = " "
    format-mounted-prefix-font = 4
    format-mounted-prefix-foreground = ''${color.blue}

    format-unmounted = <label-unmounted>
    format-unmounted-prefix = " "
    format-unmounted-prefix-font = 4

    label-mounted = "%used% "
    label-mounted-foreground = ''${color.grey}
    label-unmounted = %mountpoint%: not mounted

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

    ramp-volume-0 = 
    ramp-volume-1 = 
    ramp-volume-2 = 
    ramp-volume-3 = 
    ramp-volume-4 = 
    ramp-volume-font = 4

    click-right = pavucontrol

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

    [module/launcher]
    type = custom/text
    label = 󱄅
    label-font = 2
    label-foreground = ''${color.fg}

    click-left = rofi -show drun

    [module/sep]
    type = custom/text
    label = "  "
    label-foreground = ''${color.bg}

    [module/sep2]
    type = custom/text
    label = " 󰇙 "
    label-foreground = ''${color.indigo}

    [module/cpu_bar]
    type = internal/cpu

    interval = 0.5
    format = <label>
    format-prefix = " "
    format-prefix-font = 4

    label = "%percentage%% "
    label-foreground = ''${color.grey}

    [module/memory_bar]
    type = internal/memory

    interval = 3

    format = <label>
    format-prefix = "󰍛 "
    format-prefix-font = 4

    label = "%used% "
    label-foreground = ''${color.grey}

    [module/mplayer]
    type = custom/script
    exec = polybar-media
    tail = true

    format = <label>
    format-prefix = " "
    format-prefix-font = 4
    format-prefix-foreground = ''${color.green}

    label = %output%
    label-maxlen = 40
    label-foreground = ''${color.fg}

    [module/power]
    type = custom/text
    label = ""
    label-font = 4
    label-foreground = ''${color.red}

    click-left = rofi-power

    [module/notify]
    type = custom/script
    exec = polybar-notify
    interval = 2

    format = <label>
    label = "%output%"
    label-foreground = ''${color.yellow}

    click-left = dunstctl set-paused toggle
    click-right = rofi-notifications

    [module/control]
    type = custom/text
    label = ""
    label-font = 4
    label-foreground = ''${color.blue}

    click-left = rofi-control

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
