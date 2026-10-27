# Настройки приложений: цвета видеоплеера mpv от Matugen.
{ ... }:

{
  xdg.configFile."mpv/mpv.conf".text = ''
    include=~~/matugen-colors.conf
  '';
}
