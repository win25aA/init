-- Hyprland: все прежние сочетания клавиш, в нативном Lua API.
local mod = "SUPER"
local ipc = "ii-panel"

-- Воркспейсы 1–10; десятый остаётся на клавише 0.
for i = 1, 10 do
    local key = tostring(i % 10)
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + CTRL + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Направление колеса сохранено именно как в исходном конфиге.
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Управление окнами.
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + M", hl.dsp.exec_cmd(
    "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"
))

-- illogical-impulse: прежние сочетания клавиш, новые команды оболочки.
hl.bind(mod .. " + space", hl.dsp.exec_cmd(ipc .. " launcher"))
hl.bind(mod .. " + SHIFT + W", hl.dsp.exec_cmd(ipc .. " wallpaper"))
hl.bind(mod .. " + P", hl.dsp.exec_cmd(ipc .. " session"))
hl.bind(mod .. " + Z", hl.dsp.exec_cmd(ipc .. " control-center"))
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd(ipc .. " screenshot-fullscreen"))
hl.bind(mod .. " + CTRL + S", hl.dsp.exec_cmd(ipc .. " screenshot-region"))
hl.bind(mod .. " + mouse:275", hl.dsp.exec_cmd("playerctl previous"))
hl.bind(mod .. " + mouse:276", hl.dsp.exec_cmd("playerctl next"))

-- Приложения.
hl.bind(mod .. " + A", hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + E", hl.dsp.exec_cmd("thunar"))
hl.bind(mod .. " + W", hl.dsp.exec_cmd("firefox"))
hl.bind(mod .. " + T", hl.dsp.exec_cmd("AyuGram"))
hl.bind(mod .. " + S", hl.dsp.exec_cmd("steam"))

-- На SUPER+D и SUPER+C прежде были по два действия.
-- Сохраняем оба и их порядок: запустить приложение, затем переключить special.
hl.bind(mod .. " + D", function()
    hl.dispatch(hl.dsp.exec_cmd("vesktop"))
    hl.dispatch(hl.dsp.workspace.toggle_special("communication"))
end)
hl.bind(mod .. " + C", function()
    hl.dispatch(hl.dsp.exec_cmd("spotify"))
    hl.dispatch(hl.dsp.workspace.toggle_special("music"))
end)

-- Перемещение и изменение размера мышью (бывшие bindm).
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
