# Основа системы: Nix, пакеты, загрузка, язык, пользователь, безопасность.
{ config, lib, pkgs, inputs, ... }:

lib.mkMerge [
  # ════════════════════════════════════════════════════════════
  # Настройки самого Nix: flakes, unfree, автоочистка и оптимизация стора.
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

  # ════════════════════════════════════════════════════════════
  # Оверлеи: SpotX + собственные пакеты из ./pkgs.
  {
    nixpkgs.overlays = [
      inputs.spotx-nix.overlays.default
      (final: prev: import ../pkgs { pkgs = final; })
    ]
    # gpu-screen-recorder, собранный под драйвер NVIDIA 580, нужен только с NVIDIA.
    ++ lib.optional (config.my.gpu == "nvidia") (final: prev: {
      gpu-screen-recorder = import ../pkgs/gpu-screen-recorder-nvidia580.nix {
        inherit (prev) gpu-screen-recorder ffmpeg_7;
      };
    });
  }

  # ════════════════════════════════════════════════════════════
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

  # ════════════════════════════════════════════════════════════
  # Часовой пояс, локали и раскладка клавиатуры.
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
      variant = "";
    };
  }

  # ════════════════════════════════════════════════════════════
  # Пользователи системы.
  {
    users.users."winarowk" = {
      isNormalUser = true;
      description = "winarowk";
      extraGroups = [ "networkmanager" "wheel" "adbusers" "libvirtd" ];
    };
  }

  # ════════════════════════════════════════════════════════════
  # Home Manager: подключаем пользовательские модули из home/.
  {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = { inherit inputs; };
      backupFileExtension = "hm-backup";

      users.winarowk = import ../home;
    };
  }

  # ════════════════════════════════════════════════════════════
  # polkit, pkexec, doas.
  {
    security.polkit.enable = true;

    security.wrappers.pkexec = {
      setuid = true;
      owner = "root";
      group = "root";
      source = "${pkgs.polkit.bin}/bin/pkexec";
    };

    environment.systemPackages = with pkgs; [
      doas
    ];
  }

  # ════════════════════════════════════════════════════════════
  # Запуск «чужих» бинарников: nix-ld, AppImage, Flatpak.
  {
    programs.nix-ld.enable = true;
    services.flatpak.enable = true;
  }
]
