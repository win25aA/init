# Основа системы: Nix, пакеты, загрузка, язык, пользователь, безопасность.
{ config, lib, pkgs, inputs, ... }:

lib.mkMerge [
  # Nix
  {
    nixpkgs.config.allowUnfree = true;

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
    nix.settings.auto-optimise-store = true;
  }

  # Оверлеи
  {
    nixpkgs.overlays = [
      inputs.spotx-nix.overlays.default
      (final: prev: import ../pkgs { pkgs = final; })
    ];
  }

  # Загрузчик GRUB с темой. Режим (uefi/bios) и диск задаются в hosts/<имя-пк>.
  (
    let
      cfg = config.my.boot;
    in
    {
      boot.loader.grub = {
        enable = true;
        theme = ../grub-theme;
        useOSProber = true;
        device = if cfg.mode == "bios" then cfg.grubDevice else "nodev";
        efiSupport = cfg.mode == "uefi";
      };

      boot.loader.efi.canTouchEfiVariables = lib.mkIf (cfg.mode == "uefi") true;
    }
  )

  # Локализация
  {
    time.timeZone = "Europe/Moscow";

    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "ru_RU.UTF-8";
      LC_IDENTIFICATION = "ru_RU.UTF-8";
      LC_MEASUREMENT = "ru_RU.UTF-8";
      LC_MONETARY = "ru_RU.UTF-8";
      LC_NAME = "ru_RU.UTF-8";
      LC_NUMERIC = "ru_RU.UTF-8";
      LC_PAPER = "ru_RU.UTF-8";
      LC_TELEPHONE = "ru_RU.UTF-8";
      LC_TIME = "ru_RU.UTF-8";
    };

    services.xserver.xkb = {
      layout = "us,ru";
      options = "grp:alt_shift_toggle";
    };
  }

  # Пользователи системы.
  {
    users.users."winarowk" = {
      isNormalUser = true;
      description = "winarowk";
      extraGroups = [ "networkmanager" "wheel" "adbusers" "libvirtd" ];
    };
  }

  # Home Manager
  {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = { inherit inputs; };
      backupFileExtension = "hm-backup";

      users.winarowk = import ../home;
    };
  }

  # polkit.
  {
    security.polkit.enable = true;
    security.polkit.enablePkexecWrapper = true;

    systemd.user.services.polkit-gnome-authentication-agent = {
      description = "Polkit authentication agent";
      wantedBy = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
      };
    };
  }

  # nix-ld, AppImage и Flatpak
  {
    programs.nix-ld.enable = true;
    services.flatpak.enable = true;
  }
]
