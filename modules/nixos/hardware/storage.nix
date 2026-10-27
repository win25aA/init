# Диски, файловые системы и утилиты для них.
{ pkgs, ... }:

{
  boot.supportedFilesystems = [ "btrfs" ];

  fileSystems."/mnt/games" = {
    device = "/dev/disk/by-uuid/3f80c736-41e1-4e16-a46e-716f4650aa8b";
    fsType = "ext4";
    options = [ "users" "nofail" "x-systemd.automount" "exec" ];
  };

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
