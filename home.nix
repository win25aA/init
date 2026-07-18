{ config, pkgs, inputs, ... }:

{
  imports = [
    ./modules/hyprland.nix
    ./modules/niri.nix
    ./modules/kitty.nix
    ./modules/fish.nix
    ./modules/starship.nix
    ./modules/fastfetch.nix
    ./modules/matugen.nix
    ./modules/nodejs.nix
    ./modules/btop.nix
  ];

  home.stateVersion = "26.11";

  home.packages = with pkgs; [
  ];

  programs.home-manager.enable = true;
}
