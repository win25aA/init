# Личные настройки

Здесь настройки пользователя winarowk. Установка основных программ находится в [системном разделе](../nixos/programs/default.nix). Начинай с [default.nix](default.nix).

[Назад к карте конфига](../../README.md)

## apps

| Файл | Для чего |
| --- | --- |
| [default.nix](apps/default.nix) | Настройки отдельных приложений |
| [mpv.nix](apps/mpv.nix) | Подключение цветов для видеоплеера mpv |

## Вход в раздел

| Файл | Для чего |
| --- | --- |
| [default.nix](default.nix) | Точка входа раздела |

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
| [appearance.nix](desktop/wayland/hyprland/appearance.nix) | Внешний вид окон и рабочего стола |
| [autostart.nix](desktop/wayland/hyprland/autostart.nix) | Программы при входе в сессию |
| [binds.nix](desktop/wayland/hyprland/binds.nix) | Сочетания клавиш Hyprland |
| [default.nix](desktop/wayland/hyprland/default.nix) | Hyprland: настройки, мониторы и сочетания клавиш |
| [monitors.nix](desktop/wayland/hyprland/monitors.nix) | Разрешение, масштаб и расположение мониторов |
| [rules.nix](desktop/wayland/hyprland/rules.nix) | Правила для отдельных окон |

## desktop/wayland/noctalia

| Файл | Для чего |
| --- | --- |
| [default.nix](desktop/wayland/noctalia/default.nix) | Пути к живым настройкам Noctalia |

## desktop/wayland/sway

| Файл | Для чего |
| --- | --- |
| [appearance.nix](desktop/wayland/sway/appearance.nix) | Внешний вид окон и рабочего стола |
| [autostart.nix](desktop/wayland/sway/autostart.nix) | Программы при входе в сессию |
| [default.nix](desktop/wayland/sway/default.nix) | Sway: настройки, мониторы и сочетания клавиш |
| [keybindings.nix](desktop/wayland/sway/keybindings.nix) | Сочетания клавиш Sway |
| [outputs.nix](desktop/wayland/sway/outputs.nix) | Разрешение и расположение мониторов Sway |

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

## dev

| Файл | Для чего |
| --- | --- |
| [default.nix](dev/default.nix) | Пользовательское окружение разработки |
| [nodejs.nix](dev/nodejs.nix) | Каталог глобальных npm-пакетов и пользовательский PATH |

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
| [abbreviations.nix](terminal/fish/abbreviations.nix) | Сокращения команд Fish |
| [default.nix](terminal/fish/default.nix) | Командная оболочка Fish |
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
