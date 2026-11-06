# Железо: видеокарта, звук, Bluetooth, диски, печать, телефоны.
{ config, lib, pkgs, ... }:

lib.mkMerge [
  # ════════════════════════════════════════════════════════════
  # Видеокарта. Включается то, что указано в my.gpu (hosts/<имя-пк>).
  (
    let
      gpu = config.my.gpu;
    in
    lib.mkMerge [
      # Общее для любой видеокарты.
      {
        hardware.graphics = {
          enable = true;
          enable32Bit = true;
        };
      }

      # NVIDIA: ветка и тип модуля выбираются для каждого ПК.
      (lib.mkIf (gpu == "nvidia") {
        boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
        services.xserver.videoDrivers = [ "nvidia" ];

        hardware.nvidia = {
          open = config.my.nvidia.open;
          modesetting.enable = true;
          powerManagement.enable = false;
          powerManagement.finegrained = false;
          nvidiaSettings = true;
          package = config.boot.kernelPackages.nvidiaPackages.${config.my.nvidia.driver};
        };

        environment.systemPackages = [ pkgs.nvtopPackages.nvidia ];
      })

      # AMD: драйвер уже в ядре, нужен только мониторинг.
      (lib.mkIf (gpu == "amd") {
        environment.systemPackages = [ pkgs.nvtopPackages.amd ];
      })

      # Intel: драйвер уже в ядре, добавляем аппаратное декодирование видео.
      (lib.mkIf (gpu == "intel") {
        hardware.graphics.extraPackages = [ pkgs.intel-media-driver ];
        environment.systemPackages = [ pkgs.nvtopPackages.intel ];
      })
    ]
  )

  # ════════════════════════════════════════════════════════════
  # Звук: PipeWire вместо PulseAudio.
  {
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    environment.systemPackages = with pkgs; [
      wireplumber
      socat
      playerctl
    ];
  }

  # ════════════════════════════════════════════════════════════
  # Bluetooth.
  {
    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = true;
  }

  # ════════════════════════════════════════════════════════════
  # Файловые системы (дисковые утилиты — в system/programs.nix).
  # Дополнительные диски конкретного ПК подключаются в hosts/<имя-пк>.
  {
    boot.supportedFilesystems = [ "btrfs" ];
  }

  # ════════════════════════════════════════════════════════════
  # Печать (CUPS).
  {
    services.printing.enable = true;
  }

  # ════════════════════════════════════════════════════════════
  # Внешние устройства: iPhone, Android, Nintendo Switch, MediaTek.
  {
    # iPhone
    services.usbmuxd.enable = true;

    # Nintendo Switch
    programs.ns-usbloader.enable = true;

    # MediaTek (прошивка/сервисный режим) — доступ без root
    services.udev.extraRules = ''
      SUBSYSTEM=="usb", ATTR{idVendor}=="0e8d", MODE="0666", GROUP="users"
    '';
  }
]
