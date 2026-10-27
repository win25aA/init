# Sway: мониторы и привязка воркспейсов к ним.
{ ... }:

{
  wayland.windowManager.sway.config = {
    output = {
      "DVI-D-1" = {
        mode = "1440x900@74.98Hz";
        position = "0 0";
      };
      "HDMI-A-1" = {
        mode = "1024x768@70.07Hz";
        position = "1440 355";
      };
    };

    workspaceOutputAssign =
      (map (n: { workspace = toString n; output = "DVI-D-1"; }) [ 1 2 3 4 5 ])
      ++ (map (n: { workspace = toString n; output = "HDMI-A-1"; }) [ 6 7 8 9 10 ]);
  };
}
