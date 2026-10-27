# Личные настройки

Настройки пользователя winarowk. Основные программы устанавливаются в [системном разделе](../nixos/programs/default.nix). Начинай с [default.nix](default.nix).

[Назад к карте конфига](../../README.md)

## Вход в раздел

| Файл | Для чего |
| --- | --- |
| [apps.nix](apps.nix) | Настройки приложений: подключение цветов mpv |
| [default.nix](default.nix) | Точка входа раздела |
| [development.nix](development.nix) | Каталог глобальных npm-пакетов и пользовательский PATH |

## desktop

| Файл | Для чего |
| --- | --- |
| [default.nix](desktop/default.nix) | Рабочий стол и графическая сессия |

## desktop/wayland

| Файл | Для чего |
| --- | --- |
| [default.nix](desktop/wayland/default.nix) | Hyprland, Sway и оболочка Noctalia |

## desktop/wayland/hyprland

| Файл | Для чего |
| --- | --- |
| [binds.lua](desktop/wayland/hyprland/binds.lua) | Сочетания клавиш Hyprland (Lua) |
| [settings.lua](desktop/wayland/hyprland/settings.lua) | Мониторы, оформление, автозапуск и правила окон (Lua) |
| [default.nix](desktop/wayland/hyprland/default.nix) | Генерация hyprland.lua через Home Manager, systemd и подключение Noctalia |
| [binds.nix](desktop/wayland/hyprland/binds.nix) | Установка binds.lua через Home Manager |

## desktop/wayland/noctalia

| Файл | Для чего |
| --- | --- |
| [default.nix](desktop/wayland/noctalia/default.nix) | Пути к живым настройкам Noctalia |

## desktop/wayland/sway

| Файл | Для чего |
| --- | --- |
| [default.nix](desktop/wayland/sway/default.nix) | Мониторы, оформление и автозапуск Sway |
| [keybindings.nix](desktop/wayland/sway/keybindings.nix) | Сочетания клавиш Sway |

## desktop/x11/bspwm

| Файл | Для чего |
| --- | --- |
| [default.nix](desktop/x11/bspwm/default.nix) | bspwm: окна, правила и вспомогательные команды |
| [scripts.nix](desktop/x11/bspwm/scripts.nix) | Вспомогательные команды этого приложения |

## desktop/x11

| Файл | Для чего |
| --- | --- |
| [default.nix](desktop/x11/default.nix) | bspwm и его панель, меню и уведомления |
| [dunst.nix](desktop/x11/dunst.nix) | Уведомления X11 |
| [picom.nix](desktop/x11/picom.nix) | Эффекты и прозрачность X11 |
| [sxhkd.nix](desktop/x11/sxhkd.nix) | Сочетания клавиш bspwm |

## desktop/x11/polybar

| Файл | Для чего |
| --- | --- |
| [bar.nix](desktop/x11/polybar/bar.nix) | Расположение и внешний вид панели |
| [default.nix](desktop/x11/polybar/default.nix) | Панель bspwm |
| [modules.nix](desktop/x11/polybar/modules.nix) | Индикаторы и содержимое панели |
| [scripts.nix](desktop/x11/polybar/scripts.nix) | Вспомогательные команды этого приложения |

## desktop/x11/rofi

| Файл | Для чего |
| --- | --- |
| [default.nix](desktop/x11/rofi/default.nix) | Меню запуска и вспомогательные меню |
| [scripts.nix](desktop/x11/rofi/scripts.nix) | Вспомогательные команды этого приложения |

## terminal

| Файл | Для чего |
| --- | --- |
| [btop.nix](terminal/btop.nix) | Настройки монитора ресурсов |
| [default.nix](terminal/default.nix) | Kitty, Fish и консольные программы |
| [fastfetch.nix](terminal/fastfetch.nix) | Информация о системе и логотип |
| [kitty.nix](terminal/kitty.nix) | Шрифт, поведение и настройки Kitty |

## terminal/fish

| Файл | Для чего |
| --- | --- |
| [default.nix](terminal/fish/default.nix) | Сокращения, приветствие и инициализация Fish |
| [nixos-helpers.nix](terminal/fish/nixos-helpers.nix) | Команды nrs и nback: пересборка и откат |

## theming

| Файл | Для чего |
| --- | --- |
| [cursor.nix](theming/cursor.nix) | Тема и размер курсора |
| [default.nix](theming/default.nix) | Темы, курсор и цвета приложений |
| [gtk.nix](theming/gtk.nix) | Темы GTK/Qt |

## theming/matugen

| Файл | Для чего |
| --- | --- |
| [default.nix](theming/matugen/default.nix) | Генерация цветов из обоев |

## theming/matugen/templates

| Файл | Для чего |
| --- | --- |
| [btop.nix](theming/matugen/templates/btop.nix) | Шаблон цветов Matugen для btop |
| [dunst.nix](theming/matugen/templates/dunst.nix) | Шаблон цветов Matugen для dunst |
| [fish.nix](theming/matugen/templates/fish.nix) | Шаблон цветов Matugen для fish |
| [gtk.nix](theming/matugen/templates/gtk.nix) | Шаблон цветов Matugen для gtk |
| [i3lock.nix](theming/matugen/templates/i3lock.nix) | Шаблон цветов Matugen для i3lock |
| [kitty.nix](theming/matugen/templates/kitty.nix) | Шаблон цветов Matugen для kitty |
| [mpv.nix](theming/matugen/templates/mpv.nix) | Шаблон цветов Matugen для mpv |
| [picom.nix](theming/matugen/templates/picom.nix) | Шаблон цветов Matugen для picom |
| [polybar.nix](theming/matugen/templates/polybar.nix) | Шаблон цветов Matugen для polybar |
| [rofi.nix](theming/matugen/templates/rofi.nix) | Шаблон цветов Matugen для rofi |
