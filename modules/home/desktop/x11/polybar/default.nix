# polybar: бар для bspwm.
{ pkgs, ... }:

{
  imports = [
    ./scripts.nix # Вспомогательные команды этого приложения
    ./bar.nix # Расположение и внешний вид панели
    ./modules.nix # Индикаторы и содержимое панели
  ];

  home.packages = with pkgs; [ polybarFull playerctl dunst ];
  fonts.fontconfig.enable = true;
}
