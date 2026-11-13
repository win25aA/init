# Рабочий стол (системная часть): экран входа, сессии, порталы, шрифты, темы.
{ config, lib, pkgs, ... }:

lib.mkMerge [
  # X-сервер и совместимость X11-приложений.
  {
    services.xserver.enable = true;
    services.xserver.dpi = 96;
  }

  # SDDM
  {
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      theme = "simple-sddm-2";
      extraPackages = with pkgs.kdePackages; [
        qtmultimedia
        qtsvg
        qtimageformats
        qtvirtualkeyboard
      ];
    };

    environment.systemPackages = with pkgs; [
      simple-sddm-2-theme
    ];

    systemd.tmpfiles.rules = [
      "d /var/lib/sddm-wallpaper 0755 winarowk users - -"
    ];
  }

  # Wayland
  {
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    environment.systemPackages = with pkgs; [
      noctalia-nvml
      xwayland-satellite
      brightnessctl
    ];
  }

  # Hyprland: настройки в home/hyprland
  {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };
  }

  # SwayFX: настройки в home/sway.nix
  (
    let
      nvidia = config.my.gpu == "nvidia" && !config.my.nvidia.prime.enable;
    in
    {
      programs.sway = {
        enable = true;
        package = pkgs.swayfx;
        wrapperFeatures.gtk = true;
        extraOptions = lib.optional nvidia "--unsupported-gpu";
        extraSessionCommands = lib.optionalString nvidia ''
          export WLR_NO_HARDWARE_CURSORS=1
          export LIBVA_DRIVER_NAME=nvidia
          export GBM_BACKEND=nvidia-drm
          export __GLX_VENDOR_LIBRARY_NAME=nvidia
          export NVD_BACKEND=direct
        '' + ''
          export XDG_CURRENT_DESKTOP=sway
          export XDG_SESSION_DESKTOP=sway
          export XDG_SESSION_TYPE=wayland
        '';
      };
    }
  )

  # XDG-порталы
  {
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

      config.common.default = [ "gtk" ];

      config.sway = {
        default = [ "gtk" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
      };

      wlr = {
        enable = true;
        settings.screencast = {
          max_fps = 60;
          chooser_type = "dmenu";
          chooser_cmd = "${pkgs.wmenu}/bin/wmenu -p 'Select a screen to share:' -l 10";
        };
      };
    };
  }

  # Шрифты.
  {
    fonts.enableDefaultPackages = false;

    fonts.fontconfig.defaultFonts = {
      sansSerif = [ "DejaVu Sans" "Liberation Sans" ];
      serif     = [ "DejaVu Serif" "Liberation Serif" ];
      monospace = [ "DejaVu Sans Mono" "Liberation Mono" ];
      emoji     = [ "Noto Color Emoji" ];
    };

    fonts.packages = with pkgs; [
      dejavu_fonts
      freefont_ttf
      nerd-fonts.jetbrains-mono
      liberation_ttf
      unifont
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      corefonts
    ];
  }

  # Темы: пользовательские настройки в home/theming.nix
  {
    programs.dconf.enable = true;

    environment.systemPackages = with pkgs; [
      adw-gtk3
      papirus-icon-theme
      matugen
    ];
  }
]
