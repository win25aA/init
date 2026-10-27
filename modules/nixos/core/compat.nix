# Запуск «чужих» бинарников: nix-ld, AppImage, Flatpak.
{ pkgs, ... }:

{
  programs.nix-ld.enable = true;
  services.flatpak.enable = true;

  environment.systemPackages = with pkgs; [
    appimage-run
  ];
}
