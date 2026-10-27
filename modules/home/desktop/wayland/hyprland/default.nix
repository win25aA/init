# Hyprland: основа. Остальное разложено по соседним файлам.
{ config, ... }:

{
  imports = [
    ./monitors.nix
    ./appearance.nix
    ./autostart.nix
    ./binds.nix
    ./rules.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    xwayland.enable = true;
    # ниже удалить для анстейбла
    package = null;
    portalPackage = null;

    configType = "hyprlang";

    settings = {
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
