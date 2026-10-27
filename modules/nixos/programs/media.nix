# Музыка, видео, картинки, запись экрана.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # музыка
    spotify-session      # pkgs/spotify-session.nix
    amberol
    musikcube
    cava

    # видео и картинки
    mpv
    loupe

    # запись экрана
    gpu-screen-recorder
    gpu-screen-recorder-gtk
  ];
}
