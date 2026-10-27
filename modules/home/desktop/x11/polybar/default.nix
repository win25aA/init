# polybar: бар для bspwm.
{ pkgs, ... }:

{
  imports = [
    ./scripts.nix
    ./bar.nix
    ./modules.nix
  ];

  home.packages = with pkgs; [ polybarFull playerctl dunst ];
  fonts.fontconfig.enable = true;
}
