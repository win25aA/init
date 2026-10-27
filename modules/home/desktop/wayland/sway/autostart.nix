# Sway: автозапуск.
{ pkgs, ... }:

{
  wayland.windowManager.sway.config.startup = [
    {
      command = "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE";
    }
    { command = "noctalia"; }
    { command = "AmneziaVPN"; }
  ];
}
