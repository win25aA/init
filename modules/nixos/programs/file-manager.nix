# Файловый менеджер Thunar: превью, корзина и монтирование (gvfs).
{ pkgs, ... }:

{
  services.gvfs.enable = true;

  environment.systemPackages = with pkgs; [
    thunar
    tumbler
    ffmpegthumbnailer
  ];
}
