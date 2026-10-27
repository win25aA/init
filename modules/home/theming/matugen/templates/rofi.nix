# matugen: Цвета для rofi.
# Регистрация шаблона в config.toml + сам шаблон.
{ ... }:

{
  xdg.configFile."matugen/config.toml".text = ''
    [templates.rofi]
    input_path = "~/.config/matugen/rofi-colors.rasi"
    output_path = "~/.config/rofi/matugen-colors.rasi"
  '';

  xdg.configFile."matugen/rofi-colors.rasi".text = ''
    * {
        bg:     {{colors.surface.default.hex}};
        bg-alt: {{colors.surface_container.default.hex}};
        bg-sel: {{colors.surface_container_highest.default.hex}};
        fg:     {{colors.on_surface.default.hex}};
        grey:   {{colors.outline.default.hex}};
        accent: {{colors.primary.default.hex}};
        active: {{colors.secondary.default.hex}};
        urgent: {{colors.error.default.hex}};
    }
  '';
}
