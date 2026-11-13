-- Hyprland: оформление, автозапуск и правила окон

-- Мониторы и NVIDIA: hosts/<имя-пк>

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

-- Правила слоёв
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

-- Для vesktop правило special:communication перекрывает workspace 4.
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
    hl.exec_cmd("noctalia")
    hl.exec_cmd("AmneziaVPN")
end)
