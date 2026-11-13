# Железо: видеокарта, звук, Bluetooth, диски, печать, телефоны.
{ config, lib, pkgs, ... }:

lib.mkMerge [
  # Видеокарта: my.gpu в hosts/<имя-пк>
  (
    let
      gpu = config.my.gpu;
    in
    lib.mkMerge [
      # Общие настройки
      {
        hardware.graphics = {
          enable = true;
          enable32Bit = true;
        };
      }

      # NVIDIA: ветка и тип модуля выбираются для каждого ПК.
      (lib.mkIf (gpu == "nvidia") {
        boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
        services.xserver.videoDrivers =
          lib.optional config.my.nvidia.prime.enable (if config.my.nvidia.prime.integratedGpu == "intel" then "modesetting" else "amdgpu")
          ++ [ "nvidia" ];

        hardware.nvidia = {
          open = config.my.nvidia.open;
          modesetting.enable = true;
          powerManagement.enable = false;
          powerManagement.finegrained = false;
          nvidiaSettings = true;
          package = config.boot.kernelPackages.nvidiaPackages.${config.my.nvidia.driver};
          prime = lib.mkIf config.my.nvidia.prime.enable ({
            offload.enable = true;
            offload.enableOffloadCmd = true;
            nvidiaBusId = config.my.nvidia.prime.nvidiaBusId;
          } // (if config.my.nvidia.prime.integratedGpu == "intel" then {
            intelBusId = config.my.nvidia.prime.integratedBusId;
          } else {
            amdgpuBusId = config.my.nvidia.prime.integratedBusId;
          }));
        };

        hardware.graphics.extraPackages = lib.optionals
          (config.my.nvidia.prime.enable && config.my.nvidia.prime.integratedGpu == "intel")
          [ pkgs.intel-media-driver ];
        environment.systemPackages = [ pkgs.nvtopPackages.nvidia ];
      })

      # AMD
      (lib.mkIf (gpu == "amd") {
        environment.systemPackages = [ pkgs.nvtopPackages.amd ];
      })

      # Intel
      (lib.mkIf (gpu == "intel") {
        hardware.graphics.extraPackages = [ pkgs.intel-media-driver ];
        environment.systemPackages = [ pkgs.nvtopPackages.intel ];
      })
    ]
  )

  # Звук
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

  # Bluetooth.
  {
    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = true;
  }

  # Файловые системы; диски ПК подключаются в hosts/<имя-пк>
  {
    boot.supportedFilesystems = [ "btrfs" ];
  }

  # Печать (CUPS).
  {
    services.printing.enable = true;
  }

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
