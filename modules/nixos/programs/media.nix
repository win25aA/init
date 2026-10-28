# Музыка, видео, картинки, запись экрана.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    spotify-session      # pkgs/spotify-session.nix
    vlc
    musikcube
    cava
    mpv
    loupe
    yt-dlp
    gpu-screen-recorder
    gpu-screen-recorder-gtk
  ];
programs.gpu-screen-recorder.enable = true;
}
