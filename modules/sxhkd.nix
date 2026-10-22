{ config, pkgs, lib, inputs, ... }:

{
  services.sxhkd = {
    enable = true;
    keybindings = {
      # воркспейсы (1–5 — основной монитор, 6–10 — второй)
      "super + {1-9,0}" = "bspc desktop -f {1-9,10}";
      "super + ctrl + {1-9,0}" = "bspc node -d {1-9,10} --follow";
      "super + {button4,button5}" = "bspc desktop -f {next,prev}.local.occupied";

      # навигация
      "super + {Left,Right,Up,Down}" = "bspc node -f {west,east,north,south}";
      "super + shift + {Left,Right,Up,Down}" = "bspc node -s {west,east,north,south}";

      # окна
      "super + f" = "bspc node -t ~fullscreen";
      "super + q" = "bspc node -c";
      "super + v" = "bspc node -t ~floating";
      "super + m" = "bspc quit";

      # то, что было в noctalia
      "super + space" = "rofi -show drun";
      "super + shift + w" = "rofi-wallpaper";
      "super + p" = "rofi-power";
      "super + z" = "rofi-control";
      "super + shift + s" = "bspwm-screenshot full";
      "super + ctrl + s" = "bspwm-screenshot region";
      "super + l" = "bspwm-lock";

      # плеер на боковых кнопках мыши (как mouse:275/276 в Hyprland)
      "super + button8" = "playerctl previous";
      "super + button9" = "playerctl next";

      # громкость с OSD
      "XF86AudioRaiseVolume" = "bspwm-volume up";
      "XF86AudioLowerVolume" = "bspwm-volume down";
      "XF86AudioMute" = "bspwm-volume mute";

      # приложения
      "super + a" = "kitty";
      "super + e" = "thunar";
      "super + w" = "firefox";
      "super + t" = "AyuGram";
      "super + s" = "steam";
      "super + d" = "vesktop";
      "super + c" = "spotify";

      # перезагрузка конфигов
      "super + Escape" = "pkill -USR1 -x sxhkd && notify-send 'sxhkd' 'Хоткеи перезагружены'";
      "super + alt + r" = "bspc wm -r";
    };
  };
}
