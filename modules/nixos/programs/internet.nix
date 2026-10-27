# Браузеры и торренты.
{ pkgs, inputs, ... }:

{
  programs.firefox.enable = true;

  environment.systemPackages = with pkgs; [
    inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".default
    qbittorrent
  ];
}
