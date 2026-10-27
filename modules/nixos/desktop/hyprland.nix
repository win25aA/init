# Hyprland (системная часть). Пользовательский конфиг: modules/home/desktop/wayland/hyprland.
{ pkgs, inputs, ... }:

let
  hyprPkgs = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    # удалить для анстейбла (вместе с input hyprland в flake.nix и кэшем ниже)
    package = hyprPkgs.hyprland;
    portalPackage = hyprPkgs.xdg-desktop-portal-hyprland;
  };

  # удалить для анстейбла: бинарный кэш Hyprland
  nix.settings = {
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };
}
