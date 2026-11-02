# Личные настройки пользователя winarowk (Home Manager).
{ ... }:

{
  imports = [
    ./hyprland # Hyprland: settings.lua, binds.lua, animations.lua
    ./sway.nix # SwayFX
    ./noctalia # Бар и оболочка Noctalia
    ./x11 # bspwm, polybar, rofi, picom, dunst
    ./terminal.nix # kitty, fastfetch, btop
    ./fish.nix # Fish и команды nrs / nback
    ./theming.nix # GTK/Qt и курсор
    ./matugen.nix # Цвета из обоев для всех программ
    ./apps.nix # mpv, npm и PATH
  ];

  # Версия совместимости Home Manager. Не менять просто ради обновления пакетов.
  home.stateVersion = "26.11";

  programs.home-manager.enable = true;
}
