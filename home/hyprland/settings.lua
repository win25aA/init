-- Hyprland 0.55+: мониторы, оформление, автозапуск и правила окон.
-- Устанавливается Home Manager; редактировать нужно этот исходный файл.

-- Мониторы и NVIDIA-переменные генерируются в default.nix
-- из настроек ПК (hosts/<имя-пк>), см. модуль "hardware".

hl.config({
    general = {
        col = {
            active_border = "rgba(00000000)",
            inactive_border = "rgba(00000000)",
        },
        gaps_in = 5,
        gaps_out = 10,
    },
    decoration = {
        rounding = 10,
        rounding_power = 2,
        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },
        blur = {
            enabled = true,
            size = 3,
            passes = 2,
            vibrancy = 0.1696,
        },
    },
    input = {
        kb_layout = "us,ru",
        kb_options = "grp:alt_shift_toggle",
    },
})

-- Layer rules: в Lua используются таблицы, а не строки Hyprlang.
hl.layer_rule({
    name = "noctalia-background-blur",
    match = { namespace = "noctalia-background-.*$" },
    blur = true,
    blur_popups = true,
    ignore_alpha = 1.0,
})
hl.layer_rule({
    name = "swaync-blur",
    match = { namespace = "swaync-.*$" },
    blur = true,
    ignore_alpha = 0.4,
})

-- Layer rules самой оболочки ii.
hl.layer_rule({ match = { namespace = "quickshell:.*" }, blur_popups = true})
hl.layer_rule({ match = { namespace = "quickshell:.*" }, blur = true})
hl.layer_rule({ match = { namespace = "quickshell:.*" }, ignore_alpha = 0.79})
hl.layer_rule({ match = { namespace = "quickshell:background" }, blur = false})
hl.layer_rule({ match = { namespace = "quickshell:bar" }, animation = "slide"})
hl.layer_rule({ match = { namespace = "quickshell:actionCenter" }, no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:cheatsheet" }, animation = "slide bottom"})
hl.layer_rule({ match = { namespace = "quickshell:dock" }, animation = "slide bottom"})
hl.layer_rule({ match = { namespace = "quickshell:screenCorners" }, animation = "popin 120%"})
hl.layer_rule({ match = { namespace = "quickshell:lockWindowPusher" }, no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:notificationPopup" }, animation = "fade"})
hl.layer_rule({ match = { namespace = "quickshell:overlay" }, no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:overlay" }, ignore_alpha = 1})
hl.layer_rule({ match = { namespace = "quickshell:overview" }, no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:osk" }, animation = "slide bottom"})
hl.layer_rule({ match = { namespace = "quickshell:polkit" }, no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:popup" }, xray = false}) -- No weird color for bar tooltips (this in theory should suffice)
hl.layer_rule({ match = { namespace = "quickshell:popup" }, ignore_alpha = 1}) -- No weird color for bar tooltips (but somehow this is necessary)
hl.layer_rule({ match = { namespace = "quickshell:mediaControls" }, ignore_alpha = 1}) -- Same as above
hl.layer_rule({ match = { namespace = "quickshell:reloadPopup" }, animation = "slide"})
hl.layer_rule({ match = { namespace = "quickshell:regionSelector" }, no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:screenshot" }, no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:session" }, blur = true})
hl.layer_rule({ match = { namespace = "quickshell:session" }, no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:session" }, ignore_alpha = 0})
hl.layer_rule({ match = { namespace = "quickshell:sidebarRight" }, animation = "slide right"})
hl.layer_rule({ match = { namespace = "quickshell:sidebarLeft" }, animation = "slide left"})
hl.layer_rule({ match = { namespace = "quickshell:verticalBar" }, animation = "slide"})
hl.layer_rule({ match = { namespace = "quickshell:osk" }, order = -1})
-- Quickshell: waffles
hl.layer_rule({ match = { namespace = "quickshell:wallpaperSelector" }, animation = "slide top"})
hl.layer_rule({ match = { namespace = "quickshell:wNotificationCenter" }, no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:wOnScreenDisplay" }, no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:wStartMenu" }, no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:wTaskView" }, ignore_alpha = 0})
hl.layer_rule({ match = { namespace = "quickshell:wTaskView" }, no_anim = true})

-- Все три исходных правила и их порядок сохранены.
-- Для vesktop позднее правило special:communication перекрывает workspace 4.
hl.window_rule({
    name = "vesktop-workspace-four",
    match = { class = "^(vesktop)$" },
    workspace = "4",
})
hl.window_rule({
    name = "spotify-special-music",
    match = { class = "^(spotify)$" },
    workspace = "special:music",
})
hl.window_rule({
    name = "vesktop-special-communication",
    match = { class = "^(vesktop)$" },
    workspace = "special:communication",
})

hl.env("XDG_SESSION_TYPE", "wayland")

-- Аналог exec-once: только старт сессии, не обычная перезагрузка конфига.
-- Systemd/D-Bus hook Home Manager уже зарегистрирован перед этим модулем.
hl.on("hyprland.start", function()
    hl.exec_cmd("ii-shell")
    hl.exec_cmd("wl-paste --type text --watch bash -c 'cliphist store && qs -c ii ipc call cliphistService update'")
    hl.exec_cmd("wl-paste --type image --watch bash -c 'cliphist store && qs -c ii ipc call cliphistService update'")
    hl.exec_cmd("test ! -x ~/.config/hypr/custom/scripts/__restore_video_wallpaper.sh || ~/.config/hypr/custom/scripts/__restore_video_wallpaper.sh")
    hl.exec_cmd("AmneziaVPN")
end)
