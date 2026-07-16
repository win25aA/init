{ config, pkgs, lib, inputs, ... }:

let
  ipc = [ "noctalia" "msg" ];

  # Воркспейсы 1-5 на DVI-D-1, 6-10 на HDMI-A-1 (как было в hyprland)
  wsOutput = n: if n <= 5 then "DVI-D-1" else "HDMI-A-1";

  # Ключи "01".."10", чтобы воркспейсы сортировались по порядку
  numberedWorkspaces = lib.listToAttrs (map (n: {
    name = (if n < 10 then "0" else "") + toString n;
    value = {
      name = toString n;
      open-on-output = wsOutput n;
    };
  }) (lib.range 1 10));

  # Mod+1..9,0 - фокус, Mod+Ctrl+1..9,0 - перенос окна
  wsBinds = lib.mergeAttrsList (map (n:
    let key = if n == 10 then "0" else toString n;
    in {
      "Mod+${key}".action.focus-workspace = toString n;
      "Mod+Ctrl+${key}".action.move-column-to-workspace = toString n;
    }) (lib.range 1 10));

  # Эмуляция special-воркспейсов из hyprland:
  # - приложение не запущено: запустить и перейти на его воркспейс
  # - мы уже на этом воркспейсе: вернуться на предыдущий (тоггл)
  # - иначе: перейти на воркспейс
  # Использование: niri-ws-toggle <воркспейс> <regex app-id> <команда запуска...>
  ws-toggle = pkgs.writeShellApplication {
    name = "niri-ws-toggle";
    runtimeInputs = [ pkgs.jq pkgs.niri ];
    text = ''
      target="$1"
      app_re="$2"
      shift 2

      focused=$(niri msg --json workspaces | jq -r '.[] | select(.is_focused) | .name // empty')
      running=$(niri msg --json windows | jq --arg re "$app_re" '[.[] | select((.app_id // "") | test($re; "i"))] | length')

      if [ "$running" -eq 0 ]; then
        niri msg action focus-workspace "$target"
        niri msg action spawn -- "$@"
      elif [ "$focused" = "$target" ]; then
        niri msg action focus-workspace-previous
      else
        niri msg action focus-workspace "$target"
      fi
    '';
  };
in
{
  programs.niri.settings = {
    # ===== Мониторы =====
    outputs."DVI-D-1" = {
      mode = { width = 1440; height = 900; refresh = 74.98; };
      position = { x = 0; y = 0; };
      scale = 1.0;
    };

    outputs."HDMI-A-1" = {
      # Нативный режим этого ТВ (16:9). Старый 1024x768@70.07 из hyprland
      # растягивал 4:3 на широкий экран, а с 70.069 всё равно не совпадал.
      mode = { width = 1280; height = 720; refresh = 60.0; };
      position = { x = 1440; y = 355; };
      scale = 1.0;
    };

    # ===== Переменные окружения (NVIDIA) =====
    # WLR_NO_HARDWARE_CURSORS не нужен: niri не на wlroots
    environment = {
      LIBVA_DRIVER_NAME = "nvidia";
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      NVD_BACKEND = "direct";
    };

    # ===== Ввод =====
    input.keyboard.xkb = {
      layout = "us,ru";
      options = "grp:alt_shift_toggle";
    };

    # ===== Именованные воркспейсы =====
    # communication и music - аналоги special-воркспейсов из hyprland
    workspaces = numberedWorkspaces // {
      "11-communication" = { name = "communication"; };
      "12-music" = { name = "music"; };
    };

    # ===== Внешний вид (аналог general/decoration) =====
    layout = {
      gaps = 10;

      # рамки были прозрачными в hyprland - выключаем
      focus-ring.enable = false;
      border.enable = false;

      # аналог decoration.shadow
      shadow = {
        enable = true;
        softness = 4;
        spread = 1;
        offset = { x = 0; y = 2; };
        color = "#1a1a1aee";
      };

      default-column-width.proportion = 0.5;
    };

    # Убирает клиентские декорации, чтобы скругление работало корректно
    prefer-no-csd = true;

    hotkey-overlay.skip-at-startup = true;

    # ===== Автозапуск =====
    spawn-at-startup = [
      { argv = [ "noctalia" ]; }
    ];

    # ===== Правила окон (аналог windowrule) =====
    window-rules = [
      # Скругление углов для всех окон (аналог decoration.rounding = 10)
      {
        geometry-corner-radius = {
          top-left = 10.0;
          top-right = 10.0;
          bottom-left = 10.0;
          bottom-right = 10.0;
        };
        clip-to-geometry = true;
      }
      {
        matches = [ { app-id = "(?i)^vesktop$"; } ];
        open-on-workspace = "communication";
      }
      {
        matches = [ { app-id = "(?i)^spotify$"; } ];
        open-on-workspace = "music";
      }
    ];

    # ===== Бинды =====
    binds = wsBinds // {
      # Скролл колесом по воркспейсам (аналог mouse_up/mouse_down)
      "Mod+WheelScrollDown" = {
        action.focus-workspace-down = [ ];
        cooldown-ms = 150;
      };
      "Mod+WheelScrollUp" = {
        action.focus-workspace-up = [ ];
        cooldown-ms = 150;
      };

      # Фокус (аналог movefocus)
      "Mod+Left".action.focus-column-left = [ ];
      "Mod+Right".action.focus-column-right = [ ];
      "Mod+Up".action.focus-window-up = [ ];
      "Mod+Down".action.focus-window-down = [ ];

      # Перемещение окон с клавиатуры
      "Mod+Ctrl+Left".action.move-column-left = [ ];
      "Mod+Ctrl+Right".action.move-column-right = [ ];
      "Mod+Ctrl+Up".action.move-window-up = [ ];
      "Mod+Ctrl+Down".action.move-window-down = [ ];

      # Окна
      "Mod+F".action.fullscreen-window = [ ];
      "Mod+Q".action.close-window = [ ];
      "Mod+V".action.toggle-window-floating = [ ];
      "Mod+M".action.quit = [ ];

      # Обзор всех воркспейсов - фишка niri
      "Mod+O".action.toggle-overview = [ ];

      # Noctalia
      "Mod+Space".action.spawn = ipc ++ [ "panel-toggle" "launcher" ];
      "Mod+Shift+W".action.spawn = ipc ++ [ "panel-toggle" "wallpaper" ];
      "Mod+P".action.spawn = ipc ++ [ "panel-toggle" "session" ];
      "Mod+Z".action.spawn = ipc ++ [ "panel-toggle" "control-center" ];
      "Mod+Ctrl+S".action.spawn = ipc ++ [ "screenshot-region" ];

      # Боковые кнопки мыши (аналог mouse:275/276)
      "Mod+MouseBack".action.spawn = [ "playerctl" "previous" ];
      "Mod+MouseForward".action.spawn = [ "playerctl" "next" ];

      # Приложения
      "Mod+A".action.spawn = "kitty";
      "Mod+E".action.spawn = "thunar";
      "Mod+W".action.spawn = "firefox";
      "Mod+T".action.spawn = "AyuGram";
      "Mod+S".action.spawn = "steam";

      # Special-воркспейсы (тоггл как в hyprland):
      # первое нажатие - запуск/переход, второе - возврат назад
      "Mod+D".action.spawn = [ (lib.getExe ws-toggle) "communication" "^vesktop$" "vesktop" ];
      "Mod+C".action.spawn = [ (lib.getExe ws-toggle) "music" "^spotify$" "spotify" ];
    };
  };
}
