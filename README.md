# Мой NixOS: что где менять

Этот репозиторий описывает систему `winarowk`. Главное правило: **установка программы** и **её личные настройки** могут находиться в разных местах.

## Сначала выбери задачу

| Хочу изменить | Открыть |
| --- | --- |
| Добавить или удалить программу | [Списки программ](modules/nixos/programs/default.nix) → нужная категория |
| Драйвер NVIDIA | [nvidia.nix](modules/nixos/hardware/nvidia.nix) |
| Звук / Bluetooth / печать | [Раздел устройств](modules/nixos/hardware/default.nix) |
| Дополнительный диск, например `/mnt/games` | [storage.nix](modules/nixos/hardware/storage.nix) |
| Интернет / DNS / VPN / zapret | [Раздел сети](modules/nixos/network/default.nix) |
| Экран входа | [sddm.nix](modules/nixos/desktop/sddm.nix) |
| Загрузочное меню GRUB | [boot.nix](modules/nixos/core/boot.nix) |
| Мониторы Hyprland | [Настройки Hyprland](modules/home/desktop/wayland/hyprland/default.nix) |
| Горячие клавиши Hyprland | [binds.nix](modules/home/desktop/wayland/hyprland/binds.nix) |
| Автозапуск Hyprland | [Настройки Hyprland](modules/home/desktop/wayland/hyprland/default.nix) |
| Внешний вид и правила окон Hyprland | [Настройки Hyprland](modules/home/desktop/wayland/hyprland/default.nix) |
| Мониторы, клавиши и автозапуск Sway | [Папка Sway](modules/home/desktop/wayland/sway/default.nix) |
| Окна, клавиши, панель и меню bspwm | [Раздел X11](modules/home/desktop/x11/default.nix) |
| Настройки Noctalia | [settings.toml](modules/home/desktop/wayland/noctalia/settings.toml), [config.toml](modules/home/desktop/wayland/noctalia/config.toml) |
| Терминал Kitty | [kitty.nix](modules/home/terminal/kitty.nix) |
| Fish, сокращения, команды `nrs` / `nback` | [Папка Fish](modules/home/terminal/fish/default.nix) |
| Темы GTK/Qt и курсор | [Раздел оформления](modules/home/theming/default.nix) |
| Цвета приложений от обоев | [Matugen и шаблоны](modules/home/theming/matugen/default.nix) |
| Шрифты системы | [fonts.nix](modules/nixos/desktop/fonts.nix) |
| Язык, часовой пояс, раскладка X11 | [locale.nix](modules/nixos/core/locale.nix) |
| Раскладка Wayland | `input` в [Hyprland](modules/home/desktop/wayland/hyprland/default.nix) или [Sway](modules/home/desktop/wayland/sway/default.nix) |

## Принцип структуры

Одна самостоятельная задача — один модуль. Короткие связанные настройки находятся вместе; отдельная папка нужна только там, где действительно несколько больших частей.

- Hyprland и Sway: основные настройки в `default.nix`, сочетания клавиш рядом отдельным файлом.
- Fish: обычные настройки и сокращения вместе, длинные команды пересборки отдельно.
- Небольшие настройки приложений и разработки: `modules/home/apps.nix` и `modules/home/development.nix`, без промежуточных папок.
- Интернет-программы и мессенджеры вместе; повседневные утилиты вместе. Драйверы, службы и крупные конфиги не смешаны.
- Matugen сохраняет отдельный шаблон для каждого приложения: там независимые форматы и цвета, а не просто списки из нескольких строк.

## Как устроены папки

- **[modules/nixos/](modules/nixos/README.md)** — вся машина: драйверы, службы, экран входа, установка программ.
- **[modules/home/](modules/home/README.md)** — личные настройки: окна, клавиши, терминал, темы и конфиги приложений.
- **[pkgs/](pkgs/README.md)** — рецепты нестандартной упаковки программ. Это не основной список установленных приложений.
- **[hosts/winarowk/](hosts/winarowk/default.nix)** — имя машины, описание её железа и подключение системы.
- **[flake.nix](flake.nix)** — внешние источники и точка сборки. **[flake.lock](flake.lock)** фиксирует точные версии; вручную его обычно не редактируют.
- `grub-theme/`, `simple-sddm-2/`, `wallpapers/` — картинки, темы и другие ресурсы, а не настройки Nix.

### Почему Hyprland есть в двух местах?

В `modules/nixos/desktop/hyprland.nix` система **устанавливает и подключает Hyprland**.
В `modules/home/desktop/wayland/hyprland/` задаётся, **как он выглядит и управляется**.
Это не дубли: пакет и настройки выполняют разные задачи.

### Что такое default.nix?

Это вход в папку. Запись `./fish` означает «подключить `fish/default.nix`».
Список `imports` перечисляет подключённые настройки; рядом с каждой строкой подписано её назначение.
Новый обычный модуль нужно добавить в этот список: само наличие файла его не включает.
Исключение: вспомогательные функции, например `bspwm/scripts.nix`, подключаются через `import`, а не через `imports`.

### В каком порядке всё подключается?

```text
flake.nix
└── hosts/winarowk/default.nix
    ├── hardware-configuration.nix
    └── modules/nixos/default.nix
        ├── core, hardware, network, desktop, programs
        └── core/home-manager.nix
            └── modules/home/default.nix
                └── desktop, theming, terminal, apps.nix, development.nix
```

Это схема подключения, не порядок запуска программ. Home Manager подключён в flake, а `core/home-manager.nix` передаёт ему пользовательские настройки.

## Как внести небольшое изменение

1. Найти задачу в таблице выше и открыть нужный файл.
2. Изменить только относящуюся к задаче настройку. Для обычного пакета из nixpkgs достаточно добавить или убрать имя в соответствующем списке программ.
3. Проверить сборку **без применения**:

   ```bash
   cd /etc/nixos
   sudo nixos-rebuild build --flake .#winarowk
   ```

4. Если сборка прошла, применить:

   ```bash
   sudo nixos-rebuild switch --flake .#winarowk
   ```

`nrs` — не просто проверка: он применяет систему, затем автоматически делает Git-коммит и push. `nback` откатывает файлы конфига в Git, а не личные данные и не запущенную систему.

## Что не менять наугад

- `system.stateVersion` и `home.stateVersion` — настройки совместимости, а не номера желаемой версии системы.
- UUID дисков и `hardware-configuration.nix` — привязка к реальному железу.
- `~/.config/...`, созданные Home Manager или Matugen: постоянную настройку нужно менять в исходном модуле или шаблоне.
- **Исключение — Noctalia:** её TOML-файлы в этом репозитории доступны через живые симлинки, и интерфейс Noctalia тоже может их менять. Перед переключением ветки сохраняй такие изменения в Git.
