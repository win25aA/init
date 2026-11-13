# noctalia (бар/оболочка для Hyprland и Sway).
# Конфиги — живые симлинки на файлы в /etc/nixos, чтобы GUI noctalia мог их менять.
{ config, osConfig, pkgs, ... }:

let
  dir = "/etc/nixos/home/noctalia";
  link = file: config.lib.file.mkOutOfStoreSymlink "${dir}/${file}";
  settings = if osConfig.my.noctaliaSettingsFile == null
    then "${dir}/settings.toml" else osConfig.my.noctaliaSettingsFile;
in
{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "noctalia-sddm-wallpaper";
      runtimeInputs = [ pkgs.coreutils ];
      text = ''
        wallpaper="''${1:-}"
        [ -f "$wallpaper" ] || exit 1
        temp="$(mktemp /var/lib/sddm-wallpaper/.wallpaper.XXXXXXXX)"
        trap 'rm -f -- "$temp"' EXIT
        install -m 0644 -- "$wallpaper" "$temp"
        mv -f -- "$temp" /var/lib/sddm-wallpaper/wallpaper
      '';
    })
  ];

  xdg.stateFile."noctalia/settings.toml".source = config.lib.file.mkOutOfStoreSymlink settings;

  xdg.configFile."noctalia/config.toml".source = link "config.toml";
}
