# polybar: сами бары (основной и для второго монитора).
{ config, ... }:

{
  xdg.configFile."polybar/config.ini".text = ''

    [global/wm]
    margin-bottom = 0
    margin-top = 0

    include-file = ${config.xdg.configHome}/polybar/matugen-colors.ini
    include-file = ${config.xdg.configHome}/polybar/modules.ini

    [bar/isa-bar]
    monitor = ''${env:MONITOR:}
    monitor-strict = false
    dpi = 96
    override-redirect = false

    bottom = false
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

    padding-left = 2
    padding-right = 2

    module-margin-left = 0
    module-margin-right = 0

    font-0 = "JetBrainsMono Nerd Font Propo:style=Bold:size=10;3"
    font-1 = "JetBrainsMono Nerd Font Propo:size=15;4"
    font-2 = "JetBrainsMono Nerd Font Propo:size=13;4"
    font-3 = "JetBrainsMono Nerd Font Propo:size=11;3"

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
}
