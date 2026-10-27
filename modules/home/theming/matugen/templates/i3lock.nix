# matugen: Цвета экрана блокировки i3lock (bspwm-lock).
# Регистрация шаблона в config.toml + сам шаблон.
{ ... }:

{
  xdg.configFile."matugen/config.toml".text = ''
    [templates.i3lock]
    input_path = "~/.config/matugen/i3lock-colors.sh"
    output_path = "~/.config/i3lock/matugen-colors.sh"
  '';

  xdg.configFile."matugen/i3lock-colors.sh".text = ''
    LOCK_BG="{{colors.surface.default.hex_stripped}}"
    LOCK_FG="{{colors.on_surface.default.hex_stripped}}"
    LOCK_DIM="{{colors.on_surface_variant.default.hex_stripped}}"
    LOCK_RING="{{colors.surface_container_high.default.hex_stripped}}"
    LOCK_ACCENT="{{colors.primary.default.hex_stripped}}"
    LOCK_VERIFY="{{colors.secondary.default.hex_stripped}}"
    LOCK_WRONG="{{colors.error.default.hex_stripped}}"
  '';
}
