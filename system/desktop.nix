# Рабочий стол (системная часть): экран входа, сессии, порталы, шрифты, темы.
{ config, lib, pkgs, ... }:

lib.mkMerge [
  # ════════════════════════════════════════════════════════════
  # X11 и XWayland.
  {
    services.xserver.enable = true;
    services.xserver.dpi = 96;
  }

  # ════════════════════════════════════════════════════════════
  # Экран входа SDDM с темой simple-sddm-2 (пакет: pkgs/simple-sddm-2-theme.nix).
  {
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      theme = "simple-sddm-2";
      extraPackages = with pkgs.kdePackages; [
        qtmultimedia
        qtsvg
        qtvirtualkeyboard
      ];
    };

    environment.systemPackages = with pkgs; [
      simple-sddm-2-theme
    ];
  }

  # ════════════════════════════════════════════════════════════
  # Общее для Wayland-сессий (Hyprland и Sway): оболочка noctalia и утилиты.
  {
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    environment.systemPackages = with pkgs; [
      noctalia-nvml
      xwayland-satellite
      brightnessctl
    ];
  }

  # ════════════════════════════════════════════════════════════
  # Hyprland и его портал из nixpkgs, без отдельного flake и фиксации версии.
  # Личные настройки: home/hyprland.
  {
    # Стандартный модуль NixOS сам выбирает pkgs.hyprland и совместимый портал.
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };
  }

  # ════════════════════════════════════════════════════════════
  # SwayFX (системная часть). Пользовательский конфиг: home/sway.nix.
  (
    let
      nvidia = config.my.gpu == "nvidia";
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

  # ════════════════════════════════════════════════════════════
  # XDG-порталы (диалоги файлов, запись экрана). Для Sway — wlr.
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

  # ════════════════════════════════════════════════════════════
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

  # ════════════════════════════════════════════════════════════
  # Темы оформления на уровне системы (GTK, иконки, matugen).
  # Пользовательские настройки GTK/Qt: home/theming.nix.
  {
    programs.dconf.enable = true;

    environment.systemPackages = with pkgs; [
      adw-gtk3
      papirus-icon-theme
      matugen
    ];
  }
]
