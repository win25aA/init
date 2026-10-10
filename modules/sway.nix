{ config, pkgs, lib, inputs, ... }:

let
  mod = "Mod4";
  ipc = "noctalia msg";
  digits = [ 1 2 3 4 5 6 7 8 9 ];

  bindWorkspaces = builtins.listToAttrs (map (n: {
    name = "${mod}+${toString n}";
    value = "workspace number ${toString n}";
  }) digits);

  bindMove = builtins.listToAttrs (map (n: {
    name = "${mod}+Ctrl+${toString n}";
    value = "move container to workspace number ${toString n}; workspace number ${toString n}";
  }) digits);
in
{
  wayland.windowManager.sway = {
    enable = true;
    package = null;
    checkConfig = false;

    config = {
      modifier = mod;
      terminal = "kitty";
      bars = [ ];

      output = {
        "DVI-D-1" = {
          mode = "1440x900@74.98Hz";
          position = "0 0";
        };
        "HDMI-A-1" = {
          mode = "1024x768@70.07Hz";
          position = "1440 355";
        };
      };

      workspaceOutputAssign =
        (map (n: { workspace = toString n; output = "DVI-D-1"; }) [ 1 2 3 4 5 ])
        ++ (map (n: { workspace = toString n; output = "HDMI-A-1"; }) [ 6 7 8 9 10 ]);

      input."type:keyboard" = {
        xkb_layout = "us,ru";
        xkb_options = "grp:alt_shift_toggle";
      };

      gaps = {
        inner = 5;
        outer = 10;
      };

      window = {
        border = 0;
        titlebar = false;
      };

      floating = {
        border = 0;
        titlebar = false;
        modifier = mod;
      };

      startup = [
        { command = "noctalia"; }
        { command = "AmneziaVPN"; }
      ];

      keybindings =
        bindWorkspaces
        // bindMove
        // {
          "${mod}+0" = "workspace number 10";
          "${mod}+Ctrl+0" = "move container to workspace number 10; workspace number 10";

          "--whole-window ${mod}+button4" = "workspace next_on_output";
          "--whole-window ${mod}+button5" = "workspace prev_on_output";

          "${mod}+Left" = "focus left";
          "${mod}+Right" = "focus right";
          "${mod}+Up" = "focus up";
          "${mod}+Down" = "focus down";

          "--to-code ${mod}+f" = "fullscreen toggle";
          "--to-code ${mod}+q" = "kill";
          "--to-code ${mod}+v" = "floating toggle";
          "--to-code ${mod}+m" = "exit";
          "--to-code ${mod}+Shift+c" = "reload";

          "${mod}+space" = "exec ${ipc} panel-toggle launcher";
          "--to-code ${mod}+Shift+w" = "exec ${ipc} panel-toggle wallpaper";
          "--to-code ${mod}+p" = "exec ${ipc} panel-toggle session";
          "--to-code ${mod}+z" = "exec ${ipc} panel-toggle control-center";
          "--to-code ${mod}+Shift+s" = "exec ${ipc} screenshot-fullscreen";
          "--to-code ${mod}+Ctrl+s" = "exec ${ipc} screenshot-region";

          "--whole-window ${mod}+BTN_SIDE" = "exec playerctl previous";
          "--whole-window ${mod}+BTN_EXTRA" = "exec playerctl next";

          "--to-code ${mod}+a" = "exec kitty";
          "--to-code ${mod}+e" = "exec thunar";
          "--to-code ${mod}+w" = "exec firefox";
          "--to-code ${mod}+t" = "exec AyuGram";
          "--to-code ${mod}+s" = "exec steam";

          "--to-code ${mod}+d" = "exec vesktop";
          "--to-code ${mod}+c" = "exec spotify";
        };
    };

    extraConfig = ''
      corner_radius 10
      blur enable
      blur_passes 2
      blur_radius 3
      shadows enable
      shadow_blur_radius 8
      shadow_color #1a1a1aee
      shadow_offset 0 0

      layer_effects "swaync-control-center" { blur enable; blur_ignore_transparent enable; corner_radius 10; shadows enable; }
      layer_effects "swaync-notification-window" { blur enable; blur_ignore_transparent enable; corner_radius 10; shadows enable; }
    '';
  };
}
