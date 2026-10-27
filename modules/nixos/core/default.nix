# Базовая система: nix, загрузка, язык, пользователи, безопасность.
{ ... }:

{
  imports = [
    ./nix.nix
    ./overlays.nix
    ./boot.nix
    ./locale.nix
    ./users.nix
    ./home-manager.nix
    ./security.nix
    ./compat.nix
  ];
}
