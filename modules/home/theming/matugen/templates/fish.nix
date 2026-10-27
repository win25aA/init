# matugen: Цвета для fish.
# Регистрация шаблона в config.toml + сам шаблон.
{ ... }:

{
  xdg.configFile."matugen/config.toml".text = ''
    [templates.fish]
    input_path = "~/.config/matugen/fish-colors.fish"
    output_path = "~/.config/fish/matugen-colors.fish"
  '';

  xdg.configFile."matugen/fish-colors.fish".text = ''
    set -U fish_color_normal {{colors.on_surface.default.hex_stripped}}
    set -U fish_color_command {{colors.tertiary.default.hex_stripped}}
    set -U fish_color_param {{colors.on_surface_variant.default.hex_stripped}}
    set -U fish_color_quote {{colors.secondary.default.hex_stripped}}
    set -U fish_color_escape {{colors.secondary.default.hex_stripped}}
    set -U fish_color_autosuggestion {{colors.outline.default.hex_stripped}}
    set -U fish_color_error {{colors.error.default.hex_stripped}}
    set -U fish_color_comment {{colors.surface_variant.default.hex_stripped}}
    set -U fish_color_selection --background={{colors.surface_container_highest.default.hex_stripped}}
    set -U fish_color_search_match --background={{colors.surface_container_highest.default.hex_stripped}}
  '';
}
