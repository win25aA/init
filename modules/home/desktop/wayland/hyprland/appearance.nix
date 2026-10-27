# Hyprland: внешний вид — отступы, скругления, тени, блюр.
{ ... }:

{
  wayland.windowManager.hyprland.settings = {
    general = {
      "col.active_border" = "rgba(00000000)";
      "col.inactive_border" = "rgba(00000000)";
      gaps_in = 5;
      gaps_out = 10;
    };

    decoration = {
      rounding = 10;
      rounding_power = 2;

      shadow = {
        enabled = true;
        range = 4;
        render_power = 3;
        color = "rgba(1a1a1aee)";
      };

      blur = {
        enabled = true;
        size = 3;
        passes = 2;
        vibrancy = 0.1696;
      };
    };

    # лейер рулы
    layerrule = [
      "blur on, blur_popups on, ignore_alpha 1.0, match:namespace noctalia-background-.*$"
      "blur on, ignore_alpha 0.4, match:namespace swaync-.*$"
    ];
  };
}
