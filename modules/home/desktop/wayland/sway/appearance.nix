# Sway: внешний вид — отступы, без рамок, скругления, блюр, тени (SwayFX).
{ ... }:

{
  wayland.windowManager.sway = {
    config = {
      gaps = {
        inner = 5;
        outer = 10;
      };

      window = {
        border = 0;
        titlebar = false;
      };

      floating = {
        border = 0;
        titlebar = false;
      };
    };

    extraConfig = ''
      corner_radius 10
      blur enable
      blur_passes 2
      blur_radius 3
      shadows enable
      shadow_blur_radius 8
      shadow_color #1a1a1aee
      shadow_offset 0 0

      layer_effects "swaync-control-center" { blur enable; blur_ignore_transparent enable; corner_radius 10; shadows enable; }
      layer_effects "swaync-notification-window" { blur enable; blur_ignore_transparent enable; corner_radius 10; shadows enable; }
    '';
  };
}
