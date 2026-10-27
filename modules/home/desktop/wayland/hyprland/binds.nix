# Hyprland: горячие клавиши.
{ ... }:

let
  ipc = "noctalia msg";
in
{
  wayland.windowManager.hyprland.settings = {
    bind =
      # Воркспейсы
      (map (n: "SUPER, ${toString n}, workspace, ${toString n}") (
        [ 1 2 3 4 5 6 7 8 9 ]
      ))
      ++ [ "SUPER, 0, workspace, 10" ]
      ++ (map (n: "SUPER CTRL, ${toString n}, movetoworkspace, ${toString n}") (
        [ 1 2 3 4 5 6 7 8 9 ]
      ))
      ++ [ "SUPER CTRL, 0, movetoworkspace, 10" ]
      ++ [
        # Навигация
        "SUPER, mouse_up, workspace, e+1"
        "SUPER, mouse_down, workspace, e-1"
        "SUPER, left, movefocus, l"
        "SUPER, right, movefocus, r"
        "SUPER, up, movefocus, u"
        "SUPER, down, movefocus, d"

        # Управление окнами
        "SUPER, F, fullscreen, 0"
        "SUPER, Q, killactive"
        "SUPER, V, togglefloating"
        "SUPER, M, exec, command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"

        # Noctalia
        "SUPER, space, exec, noctalia msg panel-toggle launcher "
        "SUPER SHIFT, W, exec, ${ipc} panel-toggle wallpaper"
        "SUPER, P, exec, ${ipc} panel-toggle session"
        "SUPER, Z, exec, ${ipc} panel-toggle control-center"
        "SUPER SHIFT, S, exec, ${ipc} screenshot-fullscreen"
        "SUPER CTRL, S, exec, ${ipc} screenshot-region"

        "SUPER, mouse:275, exec, playerctl previous"
        "SUPER, mouse:276, exec, playerctl next"

        # Приложения
        "SUPER, A, exec, kitty"
        "SUPER, E, exec, thunar"
        "SUPER, W, exec, firefox"
        "SUPER, T, exec, AyuGram"
        "SUPER, S, exec, steam"

        # Special-воркспейсы
        "SUPER, D, exec, vesktop"
        "SUPER, C, exec, spotify"
        "SUPER, D, togglespecialworkspace, communication"
        "SUPER, C, togglespecialworkspace, music"
      ];

    bindm = [
      "SUPER, mouse:272, movewindow"
      "SUPER, mouse:273, resizewindow"
    ];
  };
}
