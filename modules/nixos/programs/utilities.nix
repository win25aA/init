# Повседневные утилиты: архивы, текстовые редакторы и команды терминала.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Архивы
    peazip
    file-roller
    zip
    unzip
    gzip

    # Текстовые редакторы
    micro
    mousepad

    # Оболочка и консоль
    eza
    starship
    wget
    mtr
    hyfetch
    asciiquarium
  ];
}
