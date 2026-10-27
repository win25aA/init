# Нестандартные пакеты

Здесь не выбирается, что установить: здесь описывается, как подготовить пакет. [default.nix](default.nix) даёт пакетам имена, а [системные модули](../modules/nixos/README.md) добавляют их в систему. Noctalia уже берётся из nixpkgs; её обёртка лишь добавляет доступ к библиотекам NVIDIA.

[Назад к карте конфига](../README.md)

## Вход в раздел

| Файл | Для чего |
| --- | --- |
| [default.nix](default.nix) | Список собственных пакетов для оверлея |
| [noctalia-nvml.nix](noctalia-nvml.nix) | Обёртка Noctalia из nixpkgs для статистики NVIDIA |
| [simple-sddm-2-theme.nix](simple-sddm-2-theme.nix) | Упаковка локальной темы экрана входа |
| [spotify-session.nix](spotify-session.nix) | Обёртка Spotify/SpotX для Wayland и X11 |
