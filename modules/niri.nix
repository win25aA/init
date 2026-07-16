{ config, pkgs, lib, inputs, ... }:

let
  ipc = "noctalia msg";

  # Воркспейсы 1-5 на DVI-D-1, 6-10 на HDMI-A-1 (как было в hyprland)
  wsOutput = n: if n <= 5 then "DVI-D-1" else "HDMI-A-1";

  workspacesKdl = lib.concatMapStrings (n: ''
    workspace "${toString n}" {
        open-on-output "${wsOutput n}"
    }
  '') (lib.range 1 10);

  # Mod+1..9,0 - фокус, Mod+Ctrl+1..9,0 - перенос окна
  wsBindsKdl = lib.concatMapStrings (n:
    let key = if n == 10 then "0" else toString n;
    in ''
        Mod+${key} { focus-workspace "${toString n}"; }
        Mod+Ctrl+${key} { move-column-to-workspace "${toString n}"; }
    '') (lib.range 1 10);
in
{
  xdg.configFile."niri/config.kdl".text = ''
    // ===== Мониторы =====
    output "DVI-D-1" {
        mode "1440x900@74.98"
        position x=0 y=0
        scale 1.0
    }

    output "HDMI-A-1" {
        mode "1024x768@70.07"
        position x=1440 y=355
        scale 1.0
    }

    // ===== Переменные окружения (NVIDIA) =====
    // WLR_NO_HARDWARE_CURSORS не нужен: niri не на wlroots
    environment {
        LIBVA_DRIVER_NAME "nvidia"
        GBM_BACKEND "nvidia-drm"
        __GLX_VENDOR_LIBRARY_NAME "nvidia"
        NVD_BACKEND "direct"
    }

    // ===== Ввод =====
    input {
        keyboard {
            xkb {
                layout "us,ru"
                options "grp:alt_shift_toggle"
            }
        }
    }

    // ===== Именованные воркспейсы =====
    ${workspacesKdl}
    // аналоги special:communication и special:music из hyprland
    workspace "communication"
    workspace "music"

    // ===== Внешний вид (аналог general/decoration) =====
    layout {
        gaps 10

        // рамки были прозрачными в hyprland - выключаем
        focus-ring {
            off
        }

        border {
            off
        }

        // аналог decoration.shadow
        shadow {
            on
            softness 4
            spread 1
            offset x=0 y=2
            color "#1a1a1aee"
        }

        default-column-width { proportion 0.5; }
    }

    // Скругление углов (аналог decoration.rounding = 10)
    window-rule {
        geometry-corner-radius 10
        clip-to-geometry true
    }

    // Убирает клиентские декорации, чтобы скругление работало корректно
    prefer-no-csd

    // ===== Правила окон (аналог windowrule) =====
    window-rule {
        match app-id="(?i)^vesktop$"
        open-on-workspace "communication"
    }

    window-rule {
        match app-id="(?i)^spotify$"
        open-on-workspace "music"
    }

    // ===== Автозапуск =====
    spawn-at-startup "noctalia"

    hotkey-overlay {
        skip-at-startup
    }

    screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

    // ===== Бинды =====
    binds {
        // Воркспейсы: Mod+N / Mod+Ctrl+N
    ${wsBindsKdl}
        // Скролл колесом по воркспейсам (аналог mouse_up/mouse_down)
        Mod+WheelScrollDown cooldown-ms=150 { focus-workspace-down; }
        Mod+WheelScrollUp   cooldown-ms=150 { focus-workspace-up; }

        // Фокус (аналог movefocus)
        Mod+Left  { focus-column-left; }
        Mod+Right { focus-column-right; }
        Mod+Up    { focus-window-up; }
        Mod+Down  { focus-window-down; }

        // Перемещение окон с клавиатуры
        Mod+Ctrl+Left  { move-column-left; }
        Mod+Ctrl+Right { move-column-right; }
        Mod+Ctrl+Up    { move-window-up; }
        Mod+Ctrl+Down  { move-window-down; }

        // Окна
        Mod+F { fullscreen-window; }
        Mod+Q { close-window; }
        Mod+V { toggle-window-floating; }
        Mod+M { quit; }

        // Обзор всех воркспейсов - фишка niri
        Mod+O { toggle-overview; }

        // Noctalia
        Mod+Space   { spawn-sh "${ipc} panel-toggle launcher"; }
        Mod+Shift+W { spawn-sh "${ipc} panel-toggle wallpaper"; }
        Mod+P       { spawn-sh "${ipc} panel-toggle session"; }
        Mod+Z       { spawn-sh "${ipc} panel-toggle control-center"; }
        Mod+Ctrl+S  { spawn-sh "${ipc} screenshot-region"; }

        // Боковые кнопки мыши (аналог mouse:275/276)
        Mod+MouseBack    { spawn "playerctl" "previous"; }
        Mod+MouseForward { spawn "playerctl" "next"; }

        // Приложения
        Mod+A { spawn "kitty"; }
        Mod+E { spawn "thunar"; }
        Mod+W { spawn "firefox"; }
        Mod+T { spawn "AyuGram"; }
        Mod+S { spawn "steam"; }

        // Аналог special-воркспейсов: Mod+D/C - перейти,
        // Mod+Shift+D/C - запустить приложение
        Mod+D       { focus-workspace "communication"; }
        Mod+Shift+D { spawn "vesktop"; }
        Mod+C       { focus-workspace "music"; }
        Mod+Shift+C { spawn "spotify"; }
    }
  '';
}
