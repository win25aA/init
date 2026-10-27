# X11-сессия bspwm и всё её окружение.
{ ... }:

{
  imports = [
    ./bspwm
    ./sxhkd.nix
    ./polybar
    ./picom.nix
    ./rofi
    ./dunst.nix
  ];
}
