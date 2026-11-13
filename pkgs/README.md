# Нестандартные пакеты

Собственные пакеты и обёртки. [default.nix](default.nix) задаёт их имена, оверлей подключается в [system/base.nix](../system/base.nix). Noctalia берётся из nixpkgs; обёртка добавляет доступ к библиотекам NVIDIA.

## Вход в раздел

| Файл | Для чего |
| --- | --- |
| [default.nix](default.nix) | Имена собственных пакетов для оверлея |
| [gpu-screen-recorder-nvidia580.nix](gpu-screen-recorder-nvidia580.nix) | Версия GPU Screen Recorder для NVIDIA 580 |
| [noctalia-nvml.nix](noctalia-nvml.nix) | Обёртка Noctalia из nixpkgs для статистики NVIDIA |
| [simple-sddm-2-theme.nix](simple-sddm-2-theme.nix) | Упаковка локальной темы экрана входа |
| [spotify-session.nix](spotify-session.nix) | Обёртка Spotify/SpotX для Wayland и X11 |
