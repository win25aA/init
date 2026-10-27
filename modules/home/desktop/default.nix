# Оконные менеджеры и всё вокруг них.
{ ... }:

{
  imports = [
    ./wayland # Hyprland, Sway и оболочка Noctalia
    ./x11 # bspwm и его панель, меню и уведомления
  ];
}
