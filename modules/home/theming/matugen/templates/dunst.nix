# matugen: Цвета для dunst.
# Регистрация шаблона в config.toml + сам шаблон.
{ ... }:

{
  xdg.configFile."matugen/config.toml".text = ''
    [templates.dunst]
    input_path = "~/.config/matugen/dunst-colors.conf"
    output_path = "~/.config/dunst/dunstrc.d/matugen-colors.conf"
  '';

  xdg.configFile."matugen/dunst-colors.conf".text = ''
    [global]
        frame_color = "{{colors.primary.default.hex}}"
        separator_color = "{{colors.outline_variant.default.hex}}"

    [urgency_low]
        background = "{{colors.surface.default.hex}}"
        foreground = "{{colors.on_surface.default.hex}}"
        highlight = "{{colors.primary.default.hex}}"

    [urgency_normal]
        background = "{{colors.surface.default.hex}}"
        foreground = "{{colors.on_surface.default.hex}}"
        highlight = "{{colors.primary.default.hex}}"

    [urgency_critical]
        background = "{{colors.surface.default.hex}}"
        foreground = "{{colors.on_surface.default.hex}}"
        frame_color = "{{colors.error.default.hex}}"
        highlight = "{{colors.error.default.hex}}"
  '';
}
