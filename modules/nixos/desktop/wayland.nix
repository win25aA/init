# Общее для Wayland-сессий (Hyprland и Sway): оболочка noctalia и утилиты.
{ pkgs, ... }:

{
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.systemPackages = with pkgs; [
    noctalia-nvml
    xwayland-satellite
    brightnessctl
  ];
}
