# sxhkd: горячие клавиши для bspwm.
{ config, pkgs, lib, inputs, ... }:

{
  services.sxhkd = {
    enable = true;
    keybindings = {
      "super + {1-9,0}" = "bspc desktop -f {1-9,10}";
      "super + ctrl + {1-9,0}" = "bspc node -d {1-9,10} --follow";
      "super + {button4,button5}" = "bspc desktop -f {next,prev}.local.occupied";

      "super + {Left,Right,Up,Down}" = "bspc node -f {west,east,north,south}";
      "super + shift + {Left,Right,Up,Down}" = "bspc node -s {west,east,north,south}";

      "super + f" = "if bspc query -N -n focused.fullscreen >/dev/null; then bspc node -t tiled; else bspc node -t fullscreen; fi";
      "super + q" = "bspc node -c";
      "super + v" = "bspc node -t ~floating";
      "super + m" = "bspc quit";

      "super + space" = "rofi -show drun";
      "super + shift + w" = "rofi-wallpaper";
      "super + p" = "rofi-power";
      "super + z" = "rofi-control";
      "super + shift + s" = "bspwm-screenshot full";
      "super + ctrl + s" = "bspwm-screenshot region";
      "super + l" = "bspwm-lock";

      "super + button8" = "playerctl previous";
      "super + button9" = "playerctl next";

      "XF86AudioRaiseVolume" = "bspwm-volume up";
      "XF86AudioLowerVolume" = "bspwm-volume down";
      "XF86AudioMute" = "bspwm-volume mute";

      "super + a" = "kitty";
      "super + e" = "thunar";
      "super + w" = "firefox";
      "super + t" = "AyuGram";
      "super + s" = "steam";
      "super + d" = "vesktop";
      "super + c" = "spotify";

      "super + Escape" = "pkill -USR1 -x sxhkd && notify-send 'sxhkd' 'Хоткеи перезагружены'";
      "super + alt + r" = "bspc wm -r";
    };
  };
}
