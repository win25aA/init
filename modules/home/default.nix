# Все пользовательские (Home Manager) модули winarowk.
{ ... }:

{
  imports = [
    ./desktop
    ./theming
    ./terminal
    ./apps
    ./dev
  ];

  home.stateVersion = "26.11";

  programs.home-manager.enable = true;
}
