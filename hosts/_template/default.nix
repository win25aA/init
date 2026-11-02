# Шаблон нового ПК. Скопируй папку: cp -r hosts/_template hosts/<имя-пк>
# Подробно: hosts/README.md
{ ... }:

{
  imports = [
    ./hardware-configuration.nix # Создаётся командой nixos-generate-config
    ../../modules/nixos
  ];

  # Видеокарта: nvidia | amd | intel | other
  my.gpu = "amd";

  # Загрузка: uefi (почти все новые ПК) или bios (старые).
  # Для bios ещё нужен диск: my.boot.grubDevice = "/dev/disk/by-id/...";
  my.boot.mode = "uefi";

  # Мониторы можно не указывать: любой монитор включится сам.
  # Если нужна точная раскладка (имена смотри в `hyprctl monitors`):
  # my.monitors = [
  #   { name = "DP-1"; mode = "1920x1080@144"; position = "0x0"; workspaces = [ 1 2 3 4 5 ]; }
  #   { name = "HDMI-A-1"; position = "1920x0"; workspaces = [ 6 7 8 9 10 ]; }
  # ];

  # Версия NixOS, с которой ставили этот ПК. Потом не менять.
  system.stateVersion = "26.05";
}
