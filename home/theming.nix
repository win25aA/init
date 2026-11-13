# Оформление: GTK/Qt и курсор.
{ lib, pkgs, ... }:

lib.mkMerge [
  # GTK и Qt: тёмная adw-gtk3, иконки Papirus, цвета от matugen.
  {
    gtk = {
      enable = true;
      theme = {
        name = "adw-gtk3-dark";
        package = pkgs.adw-gtk3;
      };
      iconTheme = {
        name = "Papirus";
        package = pkgs.papirus-icon-theme;
      };

      gtk3.extraCss = ''@import url("matugen-colors.css");'';
      gtk4.extraCss = ''@import url("matugen-colors.css");'';
    };

    qt = {
      enable = true;
      platformTheme.name = "gtk3";
    };
  }

  # Курсор Bibata для GTK, X11 и Sway.
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
]
