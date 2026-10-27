# matugen: генерирует цвета из обоев для всех программ.
# Общие настройки здесь, шаблоны для каждой программы — в ./templates.
# Каждый шаблон сам дописывает свою секцию в config.toml.
{ lib, ... }:

{
  imports = [
    ./templates/kitty.nix
    ./templates/btop.nix
    ./templates/fish.nix
    ./templates/gtk.nix
    ./templates/mpv.nix
    ./templates/polybar.nix
    ./templates/rofi.nix
    ./templates/dunst.nix
    ./templates/picom.nix
    ./templates/i3lock.nix
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
