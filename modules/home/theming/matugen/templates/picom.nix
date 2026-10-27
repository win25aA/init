# matugen: Цвет теней picom.
# Регистрация шаблона в config.toml + сам шаблон.
{ ... }:

{
  xdg.configFile."matugen/config.toml".text = ''
    [templates.picom]
    input_path = "~/.config/matugen/picom-colors.conf"
    output_path = "~/.config/picom/matugen-colors.conf"
  '';

  xdg.configFile."matugen/picom-colors.conf".text = ''
    shadow-color = "{{colors.shadow.default.hex}}";
  '';
}
