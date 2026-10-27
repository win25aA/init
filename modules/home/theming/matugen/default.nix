# matugen: генерирует цвета из обоев для всех программ.
# Общие настройки здесь, шаблоны для каждой программы — в ./templates.
# Каждый шаблон сам дописывает свою секцию в config.toml.
{ lib, ... }:

{
  imports = [
    ./templates/kitty.nix # Шаблон цветов Matugen для kitty
    ./templates/btop.nix # Шаблон цветов Matugen для btop
    ./templates/fish.nix # Шаблон цветов Matugen для fish
    ./templates/gtk.nix # Шаблон цветов Matugen для gtk
    ./templates/mpv.nix # Шаблон цветов Matugen для mpv
    ./templates/polybar.nix # Шаблон цветов Matugen для polybar
    ./templates/rofi.nix # Шаблон цветов Matugen для rofi
    ./templates/dunst.nix # Шаблон цветов Matugen для dunst
    ./templates/picom.nix # Шаблон цветов Matugen для picom
    ./templates/i3lock.nix # Шаблон цветов Matugen для i3lock
  ];

  # mkBefore: секция [config] всегда первой в файле
  xdg.configFile."matugen/config.toml".text = lib.mkBefore ''
    [config]
    image_mode = "dark"
    # Брать самый доминантный цвет без интерактивного выбора.
    # В matugen 4.1.0 ключ в конфиге ещё не поддержан (только CLI-флаг
    # --source-color-index, он передаётся в хуке noctalia), но оставляем
    # на будущее — после обновления matugen флаг станет не нужен.
    source_color_index = 0
  '';
}
