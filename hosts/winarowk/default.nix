# Хост winarowk: точка входа системы.
# Здесь только то, что относится именно к этой машине.
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos
  ];

  networking.hostName = "winarowk";

  system.stateVersion = "26.05";
}
