# Hyprland: правила окон.
{ ... }:

{
  wayland.windowManager.hyprland.settings = {
    windowrule = [
      "match:class ^(vesktop)$, workspace 4"
      "match:class ^(spotify)$, workspace special:music"
      "match:class ^(vesktop)$, workspace special:communication"
    ];
  };
}
