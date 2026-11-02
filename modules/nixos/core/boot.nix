# Загрузчик GRUB с темой. Режим (uefi/bios) и диск задаются в hosts/<имя-пк>.
{ config, lib, ... }:

let
  cfg = config.my.boot;
in
{
  boot.loader.grub = {
    enable = true;
    theme = ../../../grub-theme;
    useOSProber = true;
    device = if cfg.mode == "bios" then cfg.grubDevice else "nodev";
    efiSupport = cfg.mode == "uefi";
  };

  boot.loader.efi.canTouchEfiVariables = lib.mkIf (cfg.mode == "uefi") true;
}
