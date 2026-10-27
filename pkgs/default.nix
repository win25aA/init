# Собственные пакеты. Подключаются оверлеем в modules/nixos/core/overlays.nix
# и дальше доступны как обычные pkgs.<имя>.
{ pkgs, inputs }:

{
  spotify-session     = pkgs.callPackage ./spotify-session.nix { };
  soundcloud-desktop  = pkgs.callPackage ./soundcloud-desktop.nix { };
  noctalia-nvml       = pkgs.callPackage ./noctalia-nvml.nix { inherit inputs; };
  simple-sddm-2-theme = pkgs.callPackage ./simple-sddm-2-theme.nix { };
  creamlinux-installer = import inputs.creamlinux-installer { inherit pkgs; };
}
