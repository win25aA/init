# Личные настройки пользователя winarowk (Home Manager).
{ ... }:

{
  imports = [
    ./hyprland # Hyprland: settings.lua, binds.lua, animations.lua
    ./sway.nix # SwayFX
    ./noctalia # Бар и оболочка Noctalia
    ./x11 # X11-утилиты, polybar, rofi, picom, dunst
    ./terminal.nix # kitty, fastfetch, btop
    ./fish.nix # Fish, команды nrs / nback, PATH и npm
    ./theming.nix # GTK/Qt и курсор
    ./matugen.nix # Цвета из обоев для всех программ
  ];

  # Версия совместимости Home Manager. Не менять просто ради обновления пакетов.
  home.stateVersion = "26.11";

  programs.home-manager.enable = true;
}
