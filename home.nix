{ config, pkgs, ... }:

{
  # Не забудь поменять на актуальную версию
  home.stateVersion = "26.11"; 

  # Пакеты только для твоего пользователя
  home.packages = with pkgs; [
    neofetch
    htop
    # сюда же можно добавить пакеты для hyprland: waybar, rofi-wayland и т.д.
  ];

  # Пример настройки Hyprland через Home Manager
  wayland.windowManager.hyprland = {
    enable = true;
settings = {
      # Мониторы
      monitor = [
        "DVI-D-1,1440x900@74.98,0x0,1.0"
        "HDMI-A-1,1024x768@70.07,1440x355,1.0"
      ];

      # Воркспейсы
      workspace = [
        "1,monitor:DVI-D-1,default:true"
        "2,monitor:DVI-D-1"
        "3,monitor:DVI-D-1"
        "4,monitor:DVI-D-1"
        "5,monitor:DVI-D-1"
        "6,monitor:HDMI-A-1,default:true"
        "7,monitor:HDMI-A-1"
        "8,monitor:HDMI-A-1"
        "9,monitor:HDMI-A-1"
        "10,monitor:HDMI-A-1"
      ];

      # Инпут
      input = {
        kb_layout = "us,ru";
        kb_options = "grp:alt_shift_toggle";
      };

      # Автозапуск
      exec-once = [
        "noctalia"
      ];

      # Внешний вид
      general = {
        "col.active_border" = "rgba(00000000)";
        "col.inactive_border" = "rgba(00000000)";
        gaps_in = 5;
        gaps_out = 10;
      };

      decoration = {
        rounding = 10;
        rounding_power = 2;
        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };
        blur = {
          enabled = true;
          size = 3;
          passes = 2;
          vibrancy = 0.1696;
        };
      };

      # Переменные
      "$mainMod" = "SUPER";
      "$terminal" = "kitty";
      "$fileManager" = "thunar";
      "$menu" = "hyprlauncher";
      "$browser" = "firefox";
      "$telega" = "Telegram";
      "$ipc" = "noctalia msg";

      # Обычные бинды (в Nix это должен быть список строк)
      bind = [
        # Воркспейсы
        "SUPER, 1, workspace, 1"
        "SUPER, 2, workspace, 2"
        "SUPER, 3, workspace, 3"
        "SUPER, 4, workspace, 4"
        "SUPER, 5, workspace, 5"
        "SUPER, 6, workspace, 6"
        "SUPER, 7, workspace, 7"
        "SUPER, 8, workspace, 8"
        "SUPER, 9, workspace, 9"
        "SUPER, 0, workspace, 10"

        # Перемещение на воркспейсы
        "SUPER CTRL, 1, movetoworkspace, 1"
        "SUPER CTRL, 2, movetoworkspace, 2"
        "SUPER CTRL, 3, movetoworkspace, 3"
        "SUPER CTRL, 4, movetoworkspace, 4"
        "SUPER CTRL, 5, movetoworkspace, 5"
        "SUPER CTRL, 6, movetoworkspace, 6"
        "SUPER CTRL, 7, movetoworkspace, 7"
        "SUPER CTRL, 8, movetoworkspace, 8"
        "SUPER CTRL, 9, movetoworkspace, 9"
        "SUPER CTRL, 0, movetoworkspace, 10"

        # Мышь и фокус
        "SUPER, mouse_up, workspace, e+1"
        "SUPER, mouse_down, workspace, e-1"
        "SUPER, left, movefocus, l"
        "SUPER, right, movefocus, r"
        "SUPER, up, movefocus, u"
        "SUPER, down, movefocus, d"

        # Окна и система
        "SUPER, F, fullscreen, 0"
        "SUPER, Q, killactive,"
        "SUPER, V, togglefloating,"
        "SUPER, M, exec, command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"
        
        # Софт
        "SUPER, space, exec, $ipc panel-toggle launcher"
        "SUPER, A, exec, $terminal"
        "SUPER, E, exec, $fileManager"
        "SUPER, W, exec, $browser"
        "SUPER, T, exec, $telega"
        "SUPER, S, exec, steam"
        "SUPER, P, exec, $ipc panel-toggle session"
        
        # Скриншоты
        "SUPER CTRL, S, exec, grim -g \"$(slurp)\" - | swappy -f -"
        "SUPER SHIFT, S, exec, grim -g \"$(slurp)\" - | wl-copy"

        # --- ВНИМАНИЕ: ДУБЛИКАТЫ ИЗ ТВОЕГО КОНФИГА ---
        "SUPER, D, exec, vesktop"
        "SUPER, D, togglespecialworkspace, communication"
        "SUPER, C, exec, spotify"
        "SUPER, C, togglespecialworkspace, music"
        "SUPER, Z, exec, qs -c noctalia-shell ipc call plugin:assistant-panel toggle"
        "SUPER, Z, exec, $ipc panel-toggle control-center"
      ];

      # Бинды мыши (в Nix они живут в отдельном массиве bindm)
      bindm = [
        "SUPER, mouse:272, movewindow"
        "SUPER, mouse:273, resizewindow"
      ];

      # Правила окон
      windowrule = [
        "workspace 4, match:class ^(vesktop)$"
        "workspace special:music, match:class ^(Spotify)$"
        "workspace special:communication, match:class ^(vesktop)$"
      ];
    };

    # Сюда мы кидаем кастомный синтаксис (layerrule и source), 
    # который Nix может не понять напрямую. Оно добавится в конфиг "как текст".
    extraConfig = ''
      layerrule {
        name = noctalia
        match:namespace = noctalia-background-.*$
        ignore_alpha = 1.0
        blur = true
        blur_popups = true
      }

      source = ~/.config/hypr/noctalia.conf
    '';
  };



 systemd.enable = true;
 xwayland.enable = true;

  # Разрешаем Home Manager управлять собой
  programs.home-manager.enable = true;
}
