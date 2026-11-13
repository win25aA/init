# Собственные пакеты
{ pkgs }:

{
  spotify-session     = pkgs.callPackage ./spotify-session.nix { };
  noctalia-nvml       = pkgs.callPackage ./noctalia-nvml.nix { };
  simple-sddm-2-theme = pkgs.callPackage ./simple-sddm-2-theme.nix { };
}
