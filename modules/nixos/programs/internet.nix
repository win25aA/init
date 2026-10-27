# Интернет: браузер, торренты и мессенджеры.
{ pkgs, ... }:

{
  programs.firefox.enable = true;

  environment.systemPackages = with pkgs; [
    qbittorrent

    # Мессенджеры
    vesktop
    ayugram-desktop
  ];
}
