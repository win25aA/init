# NixOS-конфиг winarowk

```
flake.nix                 входы и сборка хоста
hosts/winarowk/           точка входа машины (hostName, stateVersion, железо)
pkgs/                     собственные пакеты (spotify-session, noctalia-nvml, тема SDDM)
modules/nixos/            системные модули
  core/                   nix, оверлеи, загрузка, локаль, пользователи, home-manager, безопасность, совместимость
  hardware/               nvidia, звук, bluetooth, диски, печать, внешние устройства
  network/                NetworkManager, DNS, zapret, VPN
  desktop/                X11, SDDM, Wayland, Hyprland, Sway, bspwm, порталы, шрифты, темы
  programs/               интернет, мессенджеры, медиа, игры, разработка, файлы, архивы, редакторы, CLI, ВМ
modules/home/             пользовательские модули (Home Manager)
  desktop/wayland/        hyprland/, sway/, noctalia/
  desktop/x11/            bspwm/, sxhkd, polybar/, picom, rofi/, dunst
  theming/                gtk/qt, курсор, matugen/ (шаблон на каждую программу)
  terminal/               kitty, fish/, fastfetch, btop
  apps/                   mpv
  dev/                    nodejs
grub-theme/  simple-sddm-2/  wallpapers/   ассеты
```

Каждая папка подключается через свой `default.nix`. Новый модуль — новый файл + строка в `imports` соседнего `default.nix`.
