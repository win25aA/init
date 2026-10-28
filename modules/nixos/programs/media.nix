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
    gpu-screen-recorder-gtk
  ];
  # Устанавливает backend и безопасный wrapper gsr-kms-server.
  # Совместимый FFmpeg для NVIDIA 580 подключается через core/overlays.nix.
  programs.gpu-screen-recorder.enable = true;
}
