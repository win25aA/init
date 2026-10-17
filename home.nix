{ config, pkgs, inputs, ... }:

{
  imports = [
    ./modules/bspwm.nix
    ./modules/polybar.nix
    ./modules/sxhkd.nix
    ./modules/picom.nix
    ./modules/rofi.nix
    ./modules/dunst.nix
    ./modules/wallpapers.nix
    ./modules/screenshots.nix
    ./modules/lockscreen.nix
    ./modules/clipboard.nix

    ./modules/hyprland.nix
    ./modules/kitty.nix
    ./modules/fish.nix
    ./modules/fastfetch.nix
    ./modules/matugen.nix
    ./modules/noctalia.nix
    ./modules/nodejs.nix
    ./modules/btop.nix
    ./modules/sway.nix
  ];

  home.stateVersion = "26.11";

  programs.home-manager.enable = true;
}
