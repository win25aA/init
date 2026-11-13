# Настройки winarowk
{ ... }:

{
  imports = [
    ./hardware-configuration.nix # Обнаруженное железо и корневой раздел
    ../../system # Подключение раздела nixos
  ];

  networking.hostName = "winarowk";

  # Видеокарта: nvidia | amd | intel | other
  my.gpu = "nvidia";

  # BIOS и GRUB
  my.boot = {
    mode = "bios";
    grubDevice = "/dev/disk/by-id/ata-Apacer_AS340_480GB_AFLJ1451210075";
  };

  # Два монитора: левый основной, правый маленький.
  my.monitors = [
    {
      name = "DVI-D-1";
      mode = "1440x900@74.98";
      position = "0x0";
      workspaces = [ 1 2 3 4 5 ];
    }
    {
      name = "HDMI-A-1";
      mode = "1024x768@70.07";
      position = "1440x355";
      workspaces = [ 6 7 8 9 10 ];
    }
  ];

  # Диск с играми
  fileSystems."/mnt/games" = {
    device = "/dev/disk/by-uuid/3f80c736-41e1-4e16-a46e-716f4650aa8b";
    fsType = "ext4";
    options = [ "users" "nofail" "x-systemd.automount" "exec" ];
  };

  # HDD: подключать при загрузке, но не останавливать загрузку, если диск недоступен.
  fileSystems."/mnt/harddisk" = {
    device = "/dev/disk/by-uuid/d2e1449e-2887-467a-a02c-44369a75cfc3";
    fsType = "btrfs";
    options = [ "nofail" ];
  };

  zramSwap.enable = true;

  # Версия совместимости данных, не версия NixOS. При обычном обновлении не менять.

  system.stateVersion = "26.05";
}
