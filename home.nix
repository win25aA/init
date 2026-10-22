{ config, pkgs, inputs, ... }:

{
  imports = [
    ./modules/hyprland.nix
    ./modules/kitty.nix
    ./modules/fish.nix
    ./modules/fastfetch.nix
    ./modules/matugen.nix
    ./modules/noctalia.nix
    ./modules/nodejs.nix
    ./modules/btop.nix
    ./modules/sway.nix
    ./modules/bspwm.nix
  ];

  home.stateVersion = "26.11";

  programs.home-manager.enable = true;
}
