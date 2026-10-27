# Сеть: подключение, DNS, обход блокировок, VPN.
{ ... }:

{
  imports = [
    ./networking.nix
    ./dns.nix
    ./zapret.nix
    ./vpn.nix
  ];
}
