# SwayFX: мониторы, внешний вид и автозапуск.
# Сочетания клавиш вынесены в keybindings.nix.
{ lib, osConfig, pkgs, ... }:

{
  imports = [
    ./keybindings.nix # Сочетания клавиш Sway
  ];

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
