# Все системные (NixOS) модули.
{ ... }:

{
  imports = [
    ./core
    ./hardware
    ./network
    ./desktop
    ./programs
  ];
}
