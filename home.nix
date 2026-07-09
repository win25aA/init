{ config, pkgs, inputs, ... }:

{
  imports = [
    ./modules/hyprland.nix
    ./modules/kitty.nix
    ./modules/fish.nix
    ./modules/fastfetch.nix
    ./modules/matugen.nix
    ./modules/nodejs.nix
    ./modules/btop.nix
    ./modules/wallpapers.nix
    ./modules/waybar.nix
    ./modules/rofi.nix
  ];

  home.stateVersion = "26.11";

  home.packages = with pkgs; [
  ];

  programs.home-manager.enable = true;
}
