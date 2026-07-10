{ config, pkgs, inputs, ... }:

let
  ipc = "noctalia msg";
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    xwayland.enable = true;

    configType = "hyprlang";

    settings = {
      monitor = [
        "DVI-D-1,1440x900@74.98,0x0,1"
        "HDMI-A-1,1024x768@70.07,1440x355,1"
        ",preferred,auto,1"
      ];



env = [
  "LIBVA_DRIVER_NAME,nvidia"
  "GBM_BACKEND,nvidia-drm"
  "__GLX_VENDOR_LIBRARY_NAME,nvidia"
  "NVD_BACKEND,direct"
  "WLR_NO_HARDWARE_CURSORS,1"
  "XDG_SESSION_TYPE,wayland"
]; 


      workspace =
        (map (n: "${toString n}, monitor:DVI-D-1") [ 1 2 3 4 5 ])
        ++ (map (n: "${toString n}, monitor:HDMI-A-1") [ 6 7 8 9 10 ]);

      input = {
        kb_layout = "us,ru";
        kb_options = "grp:alt_shift_toggle";
      };

      general = {
        "col.active_border" = "rgba(00000000)";
        "col.inactive_border" = "rgba(00000000)";
        gaps_in = 5;
        gaps_out = 10;
      };

      decoration = {
        rounding = 10;
        rounding_power = 2;

        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };

        blur = {
          enabled = true;
          size = 3;
          passes = 2;
          vibrancy = 0.1696;
        };
      };

      "exec-once" = [
        "noctalia"
      ];

      bind =
        (map (n: "SUPER, ${toString n}, workspace, ${toString n}") (
          [ 1 2 3 4 5 6 7 8 9 ]
        ))
        ++ [ "SUPER, 0, workspace, 10" ]
        ++ (map (n: "SUPER CTRL, ${toString n}, movetoworkspace, ${toString n}") (
          [ 1 2 3 4 5 6 7 8 9 ]
        ))
        ++ [ "SUPER CTRL, 0, movetoworkspace, 10" ]
        ++ [
          "SUPER, mouse_up, workspace, e+1"
          "SUPER, mouse_down, workspace, e-1"
          "SUPER, left, movefocus, l"
          "SUPER, right, movefocus, r"
          "SUPER, up, movefocus, u"
          "SUPER, down, movefocus, d"

          "SUPER, F, fullscreen, 0"
          "SUPER, Q, killactive"
          "SUPER, V, togglefloating"
          "SUPER, M, exec, command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"

          "SUPER, space, exec, noctalia msg panel-toggle launcher "
          "SUPER, A, exec, kitty"
          "SUPER, E, exec, thunar"
          "SUPER, W, exec, firefox"
          "SUPER, T, exec, AyuGram"
          "SUPER, S, exec, steam"
          "SUPER, P, exec, $ipc SessionMenu toggle"

          "SUPER CTRL, S, exec, grim -g \"$(slurp)\" - | swappy -f -"
          "SUPER SHIFT, S, exec, grim -g \"$(slurp)\" - | wl-copy"

          "SUPER, D, exec, vesktop"
          "SUPER, D, togglespecialworkspace, communication"
          "SUPER, C, exec, spotify"
          "SUPER, C, togglespecialworkspace, music"
          "SUPER, Z, exec, ${ipc} panel-toggle control-center"
        ];

      bindm = [
        "SUPER, mouse:272, movewindow"
        "SUPER, mouse:273, resizewindow"
      ];

      windowrule = [
        "match:class ^(vesktop)$, workspace 4"
        "match:class ^(Spotify)$, workspace special:music"
        "match:class ^(vesktop)$, workspace special:communication"
      ];

      layerrule = [
        "blur on, blur_popups on, ignore_alpha 1.0, match:namespace noctalia-background-.*$"
        "blur on, ignore_alpha 0.4, match:namespace swaync-.*$"
      ];

      source = [
        "~/.config/hypr/noctalia.conf"
      ];
    };
  };
}
