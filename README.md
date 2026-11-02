# Мой NixOS-конфиг

## Где что лежит

| Хочу поменять… | Файл |
| --- | --- |
| **Железо этого ПК**: мониторы, видеокарта, загрузка, доп. диски | `hosts/winarowk/default.nix` |
| Программы (поставить / удалить) | `system/programs.nix` |
| Видеокарта, звук, Bluetooth, диски, печать, телефоны | `system/hardware.nix` |
| Интернет, DNS, zapret, VPN | `system/network.nix` |
| Экран входа, сессии, шрифты, системные темы | `system/desktop.nix` |
| Загрузчик, язык, пользователь, настройки Nix | `system/base.nix` |
| Hyprland: внешний вид, автозапуск, правила окон | `home/hyprland/settings.lua` |
| Hyprland: сочетания клавиш | `home/hyprland/binds.lua` |
| Hyprland: анимации | `home/hyprland/animations.lua` |
| Sway | `home/sway.nix` |
| Noctalia (бар) | `home/noctalia/` (меняется через её настройки) |
| bspwm, polybar, rofi, picom, dunst | `home/x11/` |
| kitty, fastfetch, btop | `home/terminal.nix` |
| Fish: сокращения, промпт, `nrs` / `nback` / `nf` | `home/fish.nix` |
| GTK/Qt тема, курсор | `home/theming.nix` |
| Цвета из обоев (matugen) | `home/matugen.nix` |
| mpv, npm, PATH | `home/apps.nix` |
| Новый ПК | `hosts/README.md` |

Внутри больших файлов — блоки с заголовками (линия `════`).
Каждый блок отвечает за одну вещь, например «Звук и PipeWire».

## Не помню, где что-то написано

```
nf слово
```

Покажет файл и номер строки. Например: `nf HDMI`, `nf steam`, `nf kitty`.

## Команды

- `nrs` — пересобрать систему и запушить конфиг
- `nback` — откатиться к прошлой успешной сборке (`nback list` — список)
- `nf` — поиск по конфигу

## Остальные папки

- `pkgs/` — свои пакеты (собранные вручную)
- `grub-theme/`, `simple-sddm-2/` — темы загрузчика и экрана входа
- `wallpapers/` — обои
