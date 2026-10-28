# Wayland: Hyprland с illogical-impulse QS, Sway с Noctalia.
{ ... }:

{
  imports = [
    ./illogical-impulse.nix # Только QS-оболочка для Hyprland
    ./hyprland # Hyprland: настройки, мониторы и сочетания клавиш
    ./sway # Sway: настройки, мониторы и сочетания клавиш
    ./noctalia # Пути к живым настройкам Noctalia
  ];
}
