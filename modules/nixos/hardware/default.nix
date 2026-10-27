# Железо и периферия.
{ ... }:

{
  imports = [
    ./nvidia.nix # Драйвер NVIDIA и мониторинг видеокарты
    ./audio.nix # Звук и PipeWire
    ./bluetooth.nix # Bluetooth
    ./storage.nix # Дополнительные диски и дисковые утилиты
    ./printing.nix # Печать
    ./devices.nix # Android, iPhone и другие внешние устройства
  ];
}
