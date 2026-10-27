# Программы, сгруппированные по назначению.
{ ... }:

{
  imports = [
    ./internet.nix # Firefox и qBittorrent
    ./communication.nix # Мессенджеры
    ./media.nix # Музыка, видео, изображения и запись экрана
    ./gaming.nix # Steam, Wine и игровые лаунчеры
    ./development.nix # Инструменты разработки
    ./file-manager.nix # Файловый менеджер
    ./archives.nix # Архиваторы
    ./editors.nix # Текстовые редакторы
    ./cli.nix # Общие консольные утилиты
    ./virtualisation.nix # Виртуальные машины
  ];
}
