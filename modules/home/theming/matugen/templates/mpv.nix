# matugen: Цвета OSD для mpv.
# Регистрация шаблона в config.toml + сам шаблон.
{ ... }:

{
  xdg.configFile."matugen/config.toml".text = ''
    [templates.mpv]
    input_path = "~/.config/matugen/mpv-colors.conf"
    output_path = "~/.config/mpv/matugen-colors.conf"
  '';

  xdg.configFile."matugen/mpv-colors.conf".text = ''
    osd-color = "{{colors.primary.default.hex}}"
    osd-border-color = "{{colors.surface.default.hex}}"
  '';
}
