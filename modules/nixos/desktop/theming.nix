# Темы оформления на уровне системы (GTK, иконки, matugen).
# Пользовательские настройки GTK/Qt: modules/home/theming.
{ pkgs, ... }:

{
  programs.dconf.enable = true;

  environment.systemPackages = with pkgs; [
    adw-gtk3
    papirus-icon-theme
    matugen
  ];
}
