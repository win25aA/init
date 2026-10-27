# mpv: подключаем цвета OSD от matugen.
{ ... }:

{
  xdg.configFile."mpv/mpv.conf".text = ''
    include=~~/matugen-colors.conf
  '';
}
