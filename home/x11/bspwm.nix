# bspwm: окна, правила и сочетания клавиш (sxhkd). Скрипты: bspwm-scripts.nix.
{ config, lib, pkgs, inputs, ... }:

lib.mkMerge [
  # ════════════════════════════════════════════════════════════
  # bspwm: оконный менеджер, правила окон, пакеты для скриптов.
  (
    let
      xpkg = name: pkgs.${name} or pkgs.xorg.${name};

      inherit (import ./bspwm-scripts.nix { inherit pkgs config; })
        monitors wallpaper autostart lock screenshot volume;
    in

    {
      home.packages = with pkgs; [
        monitors wallpaper autostart lock screenshot volume
        feh matugen maim xclip imagemagick i3lock-color
        playerctl wireplumber libnotify clipmenu
        (xpkg "xrandr") (xpkg "xsetroot") (xpkg "xrdb") libxcvt
      ];

      xresources.properties."Xft.dpi" = 96;

      xsession.windowManager.bspwm = {
        enable = true;
        extraConfigEarly = "${monitors}/bin/bspwm-monitors";

        settings = {
          border_width = 0;
          window_gap = 10;
          split_ratio = 0.5;
          automatic_scheme = "longest_side";
          initial_polarity = "second_child";
          removal_adjustment = true;
          borderless_monocle = true;
          gapless_monocle = false;
          single_monocle = false;
          focus_follows_pointer = true;
          pointer_follows_focus = false;
          pointer_follows_monitor = true;
          pointer_modifier = "mod4";
          pointer_action1 = "move";
          pointer_action2 = "resize_side";
          pointer_action3 = "resize_corner";
        };

        rules = {
          "Pavucontrol" = { state = "floating"; center = true; rectangle = "820x520+0+0"; };
          "pavucontrol" = { state = "floating"; center = true; rectangle = "820x520+0+0"; };
          "org.pulseaudio.pavucontrol" = { state = "floating"; center = true; rectangle = "820x520+0+0"; };
          "AmneziaVPN" = { state = "floating"; center = true; };
          "Thunar:*:File Operation Progress" = { state = "floating"; };
        };

        extraConfig = "${autostart}/bin/bspwm-autostart &";
      };
    }
  )

  # ════════════════════════════════════════════════════════════
  # sxhkd: горячие клавиши для bspwm.
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
]
