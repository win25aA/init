# Hyprland: автозапуск.
{ ... }:

{
  wayland.windowManager.hyprland.settings = {
    "exec-once" = [
      "noctalia"
      "AmneziaVPN"
    ];
  };
}
