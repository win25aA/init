# Хост winarowk: точка входа системы.
# Здесь только то, что относится именно к этой машине.
{ ... }:

{
  imports = [
    ./hardware-configuration.nix # Обнаруженное железо и корневой раздел
    ../../modules/nixos # Подключение раздела nixos
  ];

  networking.hostName = "winarowk";

  # Версия совместимости данных, не версия NixOS. При обычном обновлении не менять.
  system.stateVersion = "26.05";
}
