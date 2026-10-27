# Консольные утилиты.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # оболочка
    eza
    starship

    # сеть
    wget
    mtr

    # развлечения
    hyfetch
    asciiquarium
  ];
}
