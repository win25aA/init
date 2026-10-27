# X11 (нужен для bspwm и XWayland).
{ ... }:

{
  services.xserver.enable = true;
  services.xserver.dpi = 96;
}
