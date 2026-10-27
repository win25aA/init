# Hyprland и его портал из nixpkgs, без отдельного flake и фиксации версии.
# Личные настройки: modules/home/desktop/wayland/hyprland.
{ ... }:

{
  # Стандартный модуль NixOS сам выбирает pkgs.hyprland и совместимый портал.
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
}
