# Курсор Bibata для GTK, X11 и Sway.
{ pkgs, ... }:

{
  home.pointerCursor = {
    enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;

    gtk.enable = true;
    x11.enable = true;
    sway.enable = true;
  };
}
