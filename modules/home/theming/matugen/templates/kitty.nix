# matugen: Цвета для kitty.
# Регистрация шаблона в config.toml + сам шаблон.
{ ... }:

{
  xdg.configFile."matugen/config.toml".text = ''
    [templates.kitty]
    input_path = "/home/winarowk/.config/matugen/kitty.conf"
    output_path = "~/.config/kitty/matugen-colors.conf"
  '';

  xdg.configFile."matugen/kitty.conf".text = ''
    foreground            {{colors.on_surface.default.hex}}
    selection_foreground  {{colors.surface.default.hex}}
    selection_background  {{colors.primary.default.hex}}
    cursor                {{colors.primary.default.hex}}
    cursor_text_color     {{colors.surface.default.hex}}

    color0  {{colors.surface.default.hex}}
    color1  {{colors.error.default.hex}}
    color2  {{colors.primary.default.hex}}
    color3  {{colors.secondary.default.hex}}
    color4  {{colors.tertiary.default.hex}}
    color5  {{colors.primary.default.hex}}
    color6  {{colors.secondary.default.hex}}
    color7  {{colors.on_surface.default.hex}}

    color8  {{colors.surface_variant.default.hex}}
    color9  {{colors.error.default.hex}}
    color10 {{colors.primary.default.hex}}
    color11 {{colors.secondary.default.hex}}
    color12 {{colors.tertiary.default.hex}}
    color13 {{colors.primary.default.hex}}
    color14 {{colors.secondary.default.hex}}
    color15 {{colors.on_surface.default.hex}}
  '';
}
