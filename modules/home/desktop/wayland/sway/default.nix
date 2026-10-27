# Sway (SwayFX): основа. Остальное разложено по соседним файлам.
{ ... }:

{
  imports = [
    ./outputs.nix
    ./appearance.nix
    ./autostart.nix
    ./keybindings.nix
  ];

  wayland.windowManager.sway = {
    enable = true;
    package = null;
    checkConfig = false;

    config = {
      modifier = "Mod4";
      terminal = "kitty";
      bars = [ ];

      input."type:keyboard" = {
        xkb_layout = "us,ru";
        xkb_options = "grp:alt_shift_toggle";
      };

      floating.modifier = "Mod4";
    };
  };
}
