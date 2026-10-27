# Графика: дисплейный менеджер, сессии (Hyprland / Sway / bspwm), порталы, шрифты, темы.
{ ... }:

{
  imports = [
    ./xserver.nix # Общая настройка X11
    ./sddm.nix # Экран входа и его тема
    ./wayland.nix # Noctalia и общие утилиты Wayland
    ./hyprland.nix # Установка Hyprland и портала из отдельного flake
    ./sway.nix # Установка SwayFX
    ./bspwm.nix # Включение сессии bspwm
    ./portals.nix # Порталы: выбор файлов и интеграция приложений
    ./fonts.nix # Системные шрифты
    ./theming.nix # Установка тем, иконок и Matugen
  ];
}
