# Графика: дисплейный менеджер, сессии (Hyprland / Sway / bspwm), порталы, шрифты, темы.
{ ... }:

{
  imports = [
    ./xserver.nix
    ./sddm.nix
    ./wayland.nix
    ./hyprland.nix
    ./sway.nix
    ./bspwm.nix
    ./portals.nix
    ./fonts.nix
    ./theming.nix
  ];
}
