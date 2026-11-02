# SwayFX: мониторы, внешний вид, автозапуск и сочетания клавиш.
{ lib, pkgs, osConfig, ... }:

lib.mkMerge [
  # ════════════════════════════════════════════════════════════
  # SwayFX: мониторы, внешний вид и автозапуск.
  # Сочетания клавиш вынесены в keybindings.nix.
  {
    wayland.windowManager.sway = {
      enable = true;
      package = null;
      checkConfig = false;

      config = {
        modifier = "Mod4";
        terminal = "kitty";
        bars = [ ];

        input."type:keyboard" = {
          xkb_layout = "us,ru";
          xkb_options = "grp:alt_shift_toggle";
        };

        # Мониторы и рабочие столы: из hosts/<имя-пк> (my.monitors).
        # Если список пуст, Sway сам включает все мониторы.
        output = lib.listToAttrs (map (m: {
          name = m.name;
          value = { scale = m.scale; }
            // lib.optionalAttrs (m.mode != "preferred") { mode = m.mode; }
            // lib.optionalAttrs (m.position != "auto") {
              position = lib.replaceStrings [ "x" ] [ " " ] m.position;
            };
        }) osConfig.my.monitors);
        workspaceOutputAssign = lib.concatMap (m:
          map (n: { workspace = toString n; output = m.name; }) m.workspaces
        ) osConfig.my.monitors;

        # Внешний вид
        gaps = {
          inner = 5;
          outer = 10;
        };
        window = {
          border = 0;
          titlebar = false;
        };
        floating = {
          modifier = "Mod4";
          border = 0;
          titlebar = false;
        };

        # Автозапуск
        startup = [
          {
            command = "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE";
          }
          { command = "noctalia"; }
          { command = "AmneziaVPN"; }
        ];
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

  # ════════════════════════════════════════════════════════════
  # Sway: горячие клавиши.
  (
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
      wayland.windowManager.sway.config = {
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
            "--to-code ${mod}+Shift+z" = "exec ${ipc} panel-toggle nilsonlinux/world-radio:Panel";
            "--to-code ${mod}+Shift+r" = "exec ${ipc} plugin noctalia/screen_recorder:service all toggle";
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
    }
  )
]
