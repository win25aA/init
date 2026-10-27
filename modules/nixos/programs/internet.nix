# Браузеры и торренты.
{ pkgs, ... }:

{
  programs.firefox.enable = true;

  environment.systemPackages = with pkgs; [
    qbittorrent
  ];
}
