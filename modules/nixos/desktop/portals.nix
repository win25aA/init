# XDG-порталы (диалоги файлов, запись экрана). Для Sway — wlr.
{ pkgs, ... }:

{
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

    config.common.default = [ "gtk" ];

    config.sway = {
      default = [ "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
    };

    wlr = {
      enable = true;
      settings.screencast = {
        max_fps = 60;
        chooser_type = "dmenu";
        chooser_cmd = "${pkgs.wmenu}/bin/wmenu -p 'Select a screen to share:' -l 10";
      };
    };
  };
}
