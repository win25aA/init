# Файловые системы и дисковые утилиты.
# Дополнительные диски конкретного ПК подключаются в hosts/<имя-пк>.
{ pkgs, ... }:

{
  boot.supportedFilesystems = [ "btrfs" ];

  environment.systemPackages = with pkgs; [
    gparted
    gptfdisk
    ncdu
    btrfs-progs
    exfat
    exfatprogs
    ntfs3g
    dosfstools
    mtools
  ];
}
