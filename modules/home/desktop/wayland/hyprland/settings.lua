-- Hyprland 0.55+: мониторы, оформление, автозапуск и правила окон.
-- Устанавливается Home Manager; редактировать нужно этот исходный файл.

-- Мониторы: режимы, частоты, координаты и масштаб сохранены.
hl.monitor({
    output = "DVI-D-1",
    mode = "1440x900@74.98",
    position = "0x0",
    scale = "1",
})
hl.monitor({
    output = "HDMI-A-1",
    mode = "1024x768@70.07",
    position = "1440x355",
    scale = "1",
})

for i = 1, 10 do
    hl.workspace_rule({
        workspace = tostring(i),
        monitor = i <= 5 and "DVI-D-1" or "HDMI-A-1",
    })
end

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

-- NVIDIA: все шесть переменных из прежнего конфига.
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
hl.env("WLR_NO_HARDWARE_CURSORS", "1")
hl.env("XDG_SESSION_TYPE", "wayland")

-- Аналог exec-once: только старт сессии, не обычная перезагрузка конфига.
-- Systemd/D-Bus hook Home Manager уже зарегистрирован перед этим модулем.
hl.on("hyprland.start", function()
    hl.exec_cmd("noctalia")
    hl.exec_cmd("AmneziaVPN")
end)
