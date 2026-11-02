# noctalia (бар/оболочка для Hyprland и Sway).
# Конфиги — живые симлинки на файлы в /etc/nixos, чтобы GUI noctalia мог их менять.
{ config, ... }:

let
  dir = "/etc/nixos/home/noctalia";
  link = file: config.lib.file.mkOutOfStoreSymlink "${dir}/${file}";
in
{
  xdg.stateFile."noctalia/settings.toml".source = link "settings.toml";

  xdg.configFile."noctalia/config.toml".source = link "config.toml";
}
