# Hyprland: мониторы и привязка воркспейсов к ним.
{ ... }:

{
  wayland.windowManager.hyprland.settings = {
    monitor = [
      "DVI-D-1,1440x900@74.98,0x0,1"
      "HDMI-A-1,1024x768@70.07,1440x355,1"
    ];

    workspace =
      (map (n: "${toString n}, monitor:DVI-D-1") [ 1 2 3 4 5 ])
      ++ (map (n: "${toString n}, monitor:HDMI-A-1") [ 6 7 8 9 10 ]);
  };
}
