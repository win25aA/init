# Полная оболочка ii для Hyprland. Sway продолжает запускать Noctalia.
{ config, lib, osConfig, pkgs, ... }:

let
  pkg = pkgs.illogical-impulse;
  dir = if osConfig.my.illogicalImpulseConfigDir == null
    then "/etc/nixos/home/illogical-impulse/config"
    else osConfig.my.illogicalImpulseConfigDir;
in
lib.mkMerge [
  # ════════════════════════════════════════════════════════════
  # Код оболочки из Nix store, настройки — живой каталог в репозитории.
  {
    home.packages = [ (lib.hiPrio pkg) ];
    xdg.configFile."quickshell/ii".source = "${pkg}/share/illogical-impulse";
    xdg.configFile."illogical-impulse".source = config.lib.file.mkOutOfStoreSymlink dir;
    xdg.configFile."hypr/hyprland/shellOverrides".source = config.lib.file.mkOutOfStoreSymlink "${dir}/hypr-overrides";
    xdg.configFile."hypr/hyprland/scripts".source = "${pkg}/share/illogical-impulse-hypr-scripts";
    home.file.".face".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/wallpapers/.158.jpg";
  }
]
