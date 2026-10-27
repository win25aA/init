# matugen: Цвета для polybar.
# Регистрация шаблона в config.toml + сам шаблон.
{ ... }:

{
  xdg.configFile."matugen/config.toml".text = ''
    [templates.polybar]
    input_path = "~/.config/matugen/polybar-colors.ini"
    output_path = "~/.config/polybar/matugen-colors.ini"
  '';

  xdg.configFile."matugen/polybar-colors.ini".text = ''
    [color]
    bg = {{colors.surface.default.hex}}
    bg-alt = {{colors.surface_container.default.hex}}
    fg = {{colors.on_surface.default.hex}}
    grey = {{colors.outline.default.hex}}
    indigo = {{colors.primary_container.default.hex}}
    blue = {{colors.primary.default.hex}}
    magenta = {{colors.tertiary.default.hex}}
    green = {{colors.secondary.default.hex}}
    yellow = {{colors.tertiary.default.hex}}
    red = {{colors.error.default.hex}}
  '';
}
