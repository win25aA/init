# Сеть: подключение, DNS, обход блокировок, VPN.
{ ... }:

{
  imports = [
    ./networking.nix # NetworkManager и подключение к сети
    ./dns.nix # DNS и DNS-over-TLS
    ./zapret.nix # Обход блокировок через zapret
    ./vpn.nix # AmneziaVPN
  ];
}
