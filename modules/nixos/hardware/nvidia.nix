# Видеокарта. Включается то, что указано в my.gpu (hosts/<имя-пк>).
{ config, lib, pkgs, ... }:

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

  # NVIDIA (проприетарный драйвер legacy_580).
  (lib.mkIf (gpu == "nvidia") {
    boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      open = false;
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
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
