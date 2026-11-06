# noctalia (бар/оболочка для Hyprland и Sway).
# Конфиги — живые симлинки на файлы в /etc/nixos, чтобы GUI noctalia мог их менять.
{ config, osConfig, ... }:

let
  dir = "/etc/nixos/home/noctalia";
  link = file: config.lib.file.mkOutOfStoreSymlink "${dir}/${file}";
  settings = if osConfig.my.noctaliaSettingsFile == null
    then "${dir}/settings.toml" else osConfig.my.noctaliaSettingsFile;
in
{
  xdg.stateFile."noctalia/settings.toml".source = config.lib.file.mkOutOfStoreSymlink settings;

  xdg.configFile."noctalia/config.toml".source = link "config.toml";
}
