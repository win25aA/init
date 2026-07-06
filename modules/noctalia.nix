{ config, pkgs, inputs, ... }:

{
  imports = [ inputs.noctalia.homeModules.default ];

  programs.noctalia = {
    enable = true;
    settings = {
      bar.default = {
        center = [ "media" ];
        end = [ "tray" "volume" "control-center" "session" ];
        font_weight = 700;
        start = [ "workspaces" "clock" ];
      };

      location = {
        address = "vysokaya gora tatarstan";
        latitude = 55.9122;
        longitude = 49.3128;
      };

      lockscreen_widgets = {
        enabled = false;
        schema_version = 2;
        widget_order = [
          "lockscreen-login-box@WAYLAND-1"
          "lockscreen-login-box@HDMI-A-1"
          "lockscreen-login-box@DVI-D-1"
        ];

        grid = {
          cell_size = 16;
          major_interval = 4;
          visible = true;
        };

        widget = {
          "lockscreen-login-box@DVI-D-1" = {
            box_height = 70.0;
            box_width = 400.0;
            cx = 720.0;
            cy = 781.0;
            output = "DVI-D-1";
            rotation = 0.0;
            type = "login_box";
            settings = {
              background_color = "surface_variant";
              background_opacity = 0.88;
              background_radius = 12.0;
              input_opacity = 1.0;
              input_radius = 6.0;
              show_caps_lock = true;
              show_keyboard_layout = true;
              show_login_button = true;
              show_password_hint = true;
            };
          };

          "lockscreen-login-box@HDMI-A-1" = {
            box_height = 70.0;
            box_width = 400.0;
            cx = 512.0;
            cy = 649.0;
            output = "HDMI-A-1";
            rotation = 0.0;
            type = "login_box";
            settings = {
              background_color = "surface_variant";
              background_opacity = 0.88;
              background_radius = 12.0;
              input_opacity = 1.0;
              input_radius = 6.0;
              show_caps_lock = true;
              show_keyboard_layout = true;
              show_login_button = true;
              show_password_hint = true;
            };
          };

          "lockscreen-login-box@WAYLAND-1" = {
            box_height = 70.0;
            box_width = 400.0;
            cx = 231.0;
            cy = 131.0;
            output = "WAYLAND-1";
            rotation = 0.0;
            type = "login_box";
            settings = {
              background_color = "surface_variant";
              background_opacity = 0.88;
              background_radius = 12.0;
              input_opacity = 1.0;
              input_radius = 6.0;
              show_caps_lock = true;
              show_keyboard_layout = true;
              show_login_button = true;
              show_password_hint = true;
            };
          };
        };
      };

      theme = {
        source = "wallpaper";
        templates = {
          builtin_ids = [ "btop" "cava" "hyprland" "kitty" "starship" ];
          community_ids = [ "spicetify" "neovim" ];
        };
      };

      wallpaper = {
        directory = "/home/winarowk/Pictures/wallpapers";
        default.path = "/home/winarowk/Pictures/wallpapers/wallhaven_p8o3rj.png";
        last.path = "/home/winarowk/Pictures/wallpapers/wallhaven_p8o3rj.png";
        monitors = {
          "DVI-D-1".path = "/home/winarowk/Pictures/wallpapers/wallhaven_p8o3rj.png";
          "HDMI-A-1".path = "/home/winarowk/Pictures/wallpapers/wallhaven_p8o3rj.png";
        };
      };

      widget.tray.color = "primary";
    };
  };
}
