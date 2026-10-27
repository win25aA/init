# Все пользовательские (Home Manager) модули winarowk.
{ ... }:

{
  imports = [
    ./desktop # Рабочий стол и графическая сессия
    ./theming # Темы, курсор и цвета приложений
    ./terminal # Kitty, Fish и консольные программы
    ./apps.nix # Настройки отдельных приложений (mpv)
    ./development.nix # npm-пакеты и пользовательский PATH
  ];

  # Версия совместимости Home Manager. Не менять просто ради обновления пакетов.
  home.stateVersion = "26.11";

  programs.home-manager.enable = true;
}
