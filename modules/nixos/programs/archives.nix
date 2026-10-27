# Архивы.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    peazip
    file-roller
    zip
    unzip
    gzip
  ];
}
