# Общие Wayland-утилиты и Noctalia для Sway (Hyprland использует QS).
{ pkgs, ... }:

{
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.systemPackages = with pkgs; [
    noctalia-nvml
    xwayland-satellite
    brightnessctl
  ];
}
