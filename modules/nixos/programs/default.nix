# Программы, сгруппированные по назначению.
{ ... }:

{
  imports = [
    ./internet.nix # Firefox, qBittorrent и мессенджеры
    ./media.nix # Музыка, видео, изображения и запись экрана
    ./gaming.nix # Steam, Wine и игровые лаунчеры
    ./development.nix # Инструменты разработки
    ./file-manager.nix # Файловый менеджер
    ./utilities.nix # Архивы, редакторы и консольные утилиты
    ./virtualisation.nix # Виртуальные машины
  ];
}
