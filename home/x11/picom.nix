# picom: композитор для X11 (тени, блюр, анимации).
{ config, pkgs, inputs, ... }:

{
  home.packages = [ pkgs.picom ];

  xdg.configFile."picom/picom.conf".text = ''

    backend = "glx";
    vsync = true;
    dithered-present = false;
    detect-rounded-corners = true;
    detect-client-opacity = true;
    detect-transient = true;
    use-damage = true;
    unredir-if-possible = true;
    log-level = "error";

    shadow = true;
    shadow-radius = 14;
    shadow-opacity = 0.55;
    shadow-offset-x = -12;
    shadow-offset-y = -12;
    @include "${config.xdg.configHome}/picom/matugen-colors.conf"

    fading = true;
    fade-in-step = 0.025;
    fade-out-step = 0.03;
    fade-delta = 5;

    corner-radius = 10;

    blur:
    {
        method = "dual_kawase";
        strength = 3;
    };

    rules: (

        {
            blur-background = false;
            fade = false;
        },

        {
            match = "window_type = 'normal' || window_type = 'dialog'";
            blur-background = true;
            shadow = true;
            fade = true;
            animations = (
                {
                    triggers = [ "open" ];
                    preset = "appear";
                    scale = 0.98;
                    duration = 0.24;
                },
                {
                    triggers = [ "close" ];
                    preset = "disappear";
                    scale = 0.98;
                    duration = 0.20;
                },
                {
                    triggers = [ "show" ];
                    preset = "appear";
                    scale = 1.0;
                    duration = 0.20;
                },
                {
                    triggers = [ "hide" ];
                    preset = "disappear";
                    scale = 1.0;
                    duration = 0.18;
                }
            );
        },

        {
            match = "fullscreen";
            corner-radius = 0;
            shadow = false;
        },

        {
            match = "window_type = 'tooltip'";
            corner-radius = 0;
            shadow = false;
            opacity = 0.95;
            fade = true;
        },

        {
            match = "window_type = 'dropdown_menu' || window_type = 'menu' || "
                    "window_type = 'popup' || window_type = 'popup_menu'";
            corner-radius = 0;
            shadow = false;
            fade = true;
        },

        {
            match = "class_g = 'Dunst'";
            corner-radius = 0;
            shadow = false;
            blur-background = false;
            animations = (
                {
                    triggers = [ "close", "hide" ];
                    preset = "disappear";
                    scale = 1.0;
                    duration = 0.20;
                },
                {
                    triggers = [ "open", "show" ];
                    preset = "appear";
                    scale = 1.0;
                    duration = 0.22;
                }
            );
        },

        {
            match = "class_g = 'Rofi'";
            corner-radius = 0;
            shadow = false;
            animations = (
                {
                    triggers = [ "open", "show" ];
                    preset = "appear";
                    scale = 0.99;
                    duration = 0.22;
                },
                {
                    triggers = [ "close", "hide" ];
                    preset = "disappear";
                    scale = 0.99;
                    duration = 0.18;
                }
            );
        },

        {
            match = "class_g = 'Polybar' || window_type = 'dock' || window_type = 'desktop'";
            corner-radius = 0;
            shadow = false;
            blur-background = false;
            fade = true;
        },

        {
            match = "class_g = 'slop' || class_g = 'maim' || class_g = 'i3lock'";
            corner-radius = 0;
            shadow = false;
            blur-background = false;
            fade = false;
            animations = ();
        },

        {
            match = "_GTK_FRAME_EXTENTS@ || class_g = 'firefox'";
            shadow = false;
        }
    )
  '';
}
