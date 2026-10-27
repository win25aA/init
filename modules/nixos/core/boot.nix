# Загрузчик GRUB с темой.
{ ... }:

{
  boot.loader.grub = {
    enable = true;
    device = "/dev/disk/by-id/ata-Apacer_AS340_480GB_AFLJ1451210075";
    theme = ../../../grub-theme;
    useOSProber = true;
  };
}
