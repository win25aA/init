# X11-сессия bspwm и всё её окружение.
{ ... }:

{
  imports = [
    ./bspwm.nix # bspwm и сочетания клавиш (sxhkd)
    ./polybar.nix # Панель
    ./rofi.nix # Меню запуска и вспомогательные меню
    ./picom.nix # Эффекты и прозрачность
    ./dunst.nix # Уведомления
  ];
}
