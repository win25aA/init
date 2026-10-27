# Системные настройки

Настройки всей машины. Для личного вида и клавиш смотри [пользовательский раздел](../home/README.md). Начинай с [default.nix](default.nix).

[Назад к карте конфига](../../README.md)

## core

| Файл | Для чего |
| --- | --- |
| [boot.nix](core/boot.nix) | Загрузчик GRUB и его тема |
| [compat.nix](core/compat.nix) | Запуск Flatpak, AppImage и сторонних бинарников |
| [default.nix](core/default.nix) | Основа системы: загрузка, пользователи и Nix |
| [home-manager.nix](core/home-manager.nix) | Связь системных и пользовательских настроек |
| [locale.nix](core/locale.nix) | Язык, часовой пояс и раскладка X11 |
| [nix.nix](core/nix.nix) | Настройки Nix, очистка и оптимизация хранилища |
| [overlays.nix](core/overlays.nix) | Подключение собственных пакетов и SpotX |
| [security.nix](core/security.nix) | Polkit, pkexec и doas |
| [users.nix](core/users.nix) | Учётная запись и группы пользователя |

## Вход в раздел

| Файл | Для чего |
| --- | --- |
| [default.nix](default.nix) | Точка входа раздела |

## desktop

| Файл | Для чего |
| --- | --- |
| [bspwm.nix](desktop/bspwm.nix) | Включение сессии bspwm |
| [default.nix](desktop/default.nix) | Рабочий стол и графическая сессия |
| [fonts.nix](desktop/fonts.nix) | Системные шрифты |
| [hyprland.nix](desktop/hyprland.nix) | Установка Hyprland и портала из отдельного flake |
| [portals.nix](desktop/portals.nix) | Порталы: выбор файлов и интеграция приложений |
| [sddm.nix](desktop/sddm.nix) | Экран входа и его тема |
| [sway.nix](desktop/sway.nix) | Установка SwayFX |
| [theming.nix](desktop/theming.nix) | Установка тем, иконок и Matugen |
| [wayland.nix](desktop/wayland.nix) | Noctalia и общие утилиты Wayland |
| [xserver.nix](desktop/xserver.nix) | Общая настройка X11 |

## hardware

| Файл | Для чего |
| --- | --- |
| [audio.nix](hardware/audio.nix) | Звук и PipeWire |
| [bluetooth.nix](hardware/bluetooth.nix) | Bluetooth |
| [default.nix](hardware/default.nix) | Драйверы, звук, диски и устройства |
| [devices.nix](hardware/devices.nix) | Android, iPhone и другие внешние устройства |
| [nvidia.nix](hardware/nvidia.nix) | Драйвер NVIDIA и мониторинг видеокарты |
| [printing.nix](hardware/printing.nix) | Печать |
| [storage.nix](hardware/storage.nix) | Дополнительные диски и дисковые утилиты |

## network

| Файл | Для чего |
| --- | --- |
| [default.nix](network/default.nix) | Интернет, DNS, VPN и обход блокировок |
| [dns.nix](network/dns.nix) | DNS и DNS-over-TLS |
| [networking.nix](network/networking.nix) | NetworkManager и подключение к сети |
| [vpn.nix](network/vpn.nix) | AmneziaVPN |
| [zapret.nix](network/zapret.nix) | Обход блокировок через zapret |

## programs

| Файл | Для чего |
| --- | --- |
| [default.nix](programs/default.nix) | Установка программ по категориям |
| [development.nix](programs/development.nix) | Инструменты разработки |
| [file-manager.nix](programs/file-manager.nix) | Файловый менеджер |
| [gaming.nix](programs/gaming.nix) | Steam, Wine и игровые лаунчеры |
| [internet.nix](programs/internet.nix) | Firefox, qBittorrent и мессенджеры |
| [media.nix](programs/media.nix) | Музыка, видео, изображения и запись экрана |
| [utilities.nix](programs/utilities.nix) | Архиваторы, текстовые редакторы и консольные утилиты |
| [virtualisation.nix](programs/virtualisation.nix) | Виртуальные машины |
