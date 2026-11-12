# Собственные пакеты. Подключаются оверлеем в modules/nixos/core/overlays.nix
# и дальше доступны как обычные pkgs.<имя>.
{ pkgs }:

{
  illogical-impulse = pkgs.callPackage ./illogical-impulse { };
  illogical-impulse-fonts = pkgs.callPackage ./illogical-impulse/fonts.nix { };
  spotify-session     = pkgs.callPackage ./spotify-session.nix { };
  noctalia-nvml       = pkgs.callPackage ./noctalia-nvml.nix { };
  simple-sddm-2-theme = pkgs.callPackage ./simple-sddm-2-theme.nix { };
}
