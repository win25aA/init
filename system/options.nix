# Настройки, которые отличаются от компьютера к компьютеру.
# Значения задаются в hosts/<имя-пк>/default.nix, всё остальное берёт их отсюда.
{ lib, ... }:

let
  inherit (lib) mkOption types;

  monitorType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Имя выхода, как в `hyprctl monitors`, например HDMI-A-1.";
      };
      mode = mkOption {
        type = types.str;
        default = "preferred";
        description = "Разрешение и частота, например 1920x1080@144. preferred = родное.";
      };
      position = mkOption {
        type = types.str;
        default = "auto";
        description = "Позиция, например 0x0. auto = поставить автоматически.";
      };
      scale = mkOption {
        type = types.str;
        default = "1";
        description = "Масштаб.";
      };
      workspaces = mkOption {
        type = types.listOf types.int;
        default = [ ];
        description = "Рабочие столы, закреплённые за этим монитором.";
      };
    };
  };
in
{
  options.my = {
    gpu = mkOption {
      type = types.enum [ "nvidia" "amd" "intel" "other" ];
      default = "other";
      description = "Видеокарта. От неё зависят драйверы и переменные окружения.";
    };

    boot = {
      mode = mkOption {
        type = types.enum [ "uefi" "bios" ];
        default = "uefi";
        description = "Как загружается компьютер: uefi (почти все новые ПК) или bios (старые).";
      };
      grubDevice = mkOption {
        type = types.str;
        default = "nodev";
        description = "Только для bios: диск, куда ставить GRUB (/dev/disk/by-id/...).";
      };
    };

    monitors = mkOption {
      type = types.listOf monitorType;
      default = [ ];
      description = "Точная раскладка мониторов. Пусто = любой монитор включается сам.";
    };
  };
}
