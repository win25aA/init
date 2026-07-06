{ config, pkgs, inputs, ... }:

{
  imports = [
    ./modules/hyprland.nix
    ./modules/kitty.nix
    ./modules/fish.nix
    ./modules/fastfetch.nix
    ./modules/matugen.nix
    ./modules/nodejs.nix
    ./modules/wallpapers.nix
  ];

  home.stateVersion = "26.11";

  home.packages = with pkgs; [
    htop
  ];

  programs.home-manager.enable = true;
}
