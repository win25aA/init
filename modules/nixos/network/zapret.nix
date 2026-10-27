# zapret — обход DPI (сейчас выключен: enable = false).
{ ... }:

{
  services.zapret = {
    enable = false;
    params = [
      # профиль 1 — голосовые порты Discord (UDP, без имени домена)
      "--filter-udp=50000-50100"
      "--dpi-desync=fake"
      "--dpi-desync-any-protocol"
      "--dpi-desync-repeats=6"
      "--new"
      # профиль 2 — обычные сайты (TCP), твоя рабочая стратегия
      "--filter-tcp=443"
      "--dpi-desync=fakedsplit"
      "--dpi-desync-fooling=ts"
      "--dpi-desync-split-pos=1"
    ];
    httpSupport = true;
    udpSupport = true;
    udpPorts = [ "50000:50100" ];
    configureFirewall = true;
    whitelist = [
      "youtube.com" "googlevideo.com" "ytimg.com" "ggpht.com" "youtu.be"
      "discord.com" "discordapp.com" "discord.gg" "discordapp.net"
      "instagram.com" "cdninstagram.com" "fbcdn.net"
      "rutracker.org"
    ];
  };
}
