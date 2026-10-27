# Hyprland: мониторы, внешний вид, автозапуск и правила окон.
# Сочетания клавиш вынесены в binds.nix.
{ config, ... }:

{
  imports = [
    ./binds.nix # Сочетания клавиш Hyprland
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    xwayland.enable = true;
    # Пакет и портал задаются в modules/nixos/desktop/hyprland.nix.
    package = null;
    portalPackage = null;

    configType = "hyprlang";

    settings = {
      # Мониторы и рабочие столы
      monitor = [
        "DVI-D-1,1440x900@74.98,0x0,1"
        "HDMI-A-1,1024x768@70.07,1440x355,1"
      ];

      workspace =
        (map (n: "${toString n}, monitor:DVI-D-1") [ 1 2 3 4 5 ])
        ++ (map (n: "${toString n}, monitor:HDMI-A-1") [ 6 7 8 9 10 ]);

      # Внешний вид
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

      # лейер рулы
      layerrule = [
        "blur on, blur_popups on, ignore_alpha 1.0, match:namespace noctalia-background-.*$"
        "blur on, ignore_alpha 0.4, match:namespace swaync-.*$"
      ];

      # Автозапуск
      "exec-once" = [
        "noctalia"
        "AmneziaVPN"
      ];

      # Правила окон
      windowrule = [
        "match:class ^(vesktop)$, workspace 4"
        "match:class ^(spotify)$, workspace special:music"
        "match:class ^(vesktop)$, workspace special:communication"
      ];

      # NVIDIA
      env = [
        "LIBVA_DRIVER_NAME,nvidia"
        "GBM_BACKEND,nvidia-drm"
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        "NVD_BACKEND,direct"
        "WLR_NO_HARDWARE_CURSORS,1"
        "XDG_SESSION_TYPE,wayland"
      ];

      input = {
        kb_layout = "us,ru";
        kb_options = "grp:alt_shift_toggle";
      };

      # цвета/правила от noctalia
      source = [
        "~/.config/hypr/noctalia.conf"
      ];
    };
  };

  home.activation.ensureNoctaliaConf = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/hypr"
    [ -f "$HOME/.config/hypr/noctalia.conf" ] || touch "$HOME/.config/hypr/noctalia.conf"
  '';
}
