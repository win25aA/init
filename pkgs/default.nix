# Собственные пакеты. Подключаются оверлеем в modules/nixos/core/overlays.nix
# и дальше доступны как обычные pkgs.<имя>.
{ pkgs }:

{
  spotify-session     = pkgs.callPackage ./spotify-session.nix { };
  noctalia-nvml       = pkgs.callPackage ./noctalia-nvml.nix { };
  simple-sddm-2-theme = pkgs.callPackage ./simple-sddm-2-theme.nix { };
}
