# Текстовые редакторы.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    micro
    mousepad
  ];
}
