# Нестандартные пакеты

Рецепты упаковки, а не список устанавливаемых приложений. [default.nix](default.nix) даёт пакетам имена, [системные модули](../modules/nixos/README.md) включают их. Noctalia берётся из nixpkgs, обёртка добавляет доступ к библиотекам NVIDIA.

[Назад к карте конфига](../README.md)

## Вход в раздел

| Файл | Для чего |
| --- | --- |
| [default.nix](default.nix) | Имена собственных пакетов для оверлея |
| [noctalia-nvml.nix](noctalia-nvml.nix) | Обёртка Noctalia из nixpkgs для статистики NVIDIA |
| [simple-sddm-2-theme.nix](simple-sddm-2-theme.nix) | Упаковка локальной темы экрана входа |
| [spotify-session.nix](spotify-session.nix) | Обёртка Spotify/SpotX для Wayland и X11 |

| [illogical-impulse/](illogical-impulse/default.nix) | Только QS-оболочка end-4; сохраняет свои Hyprland и темы приложений |
