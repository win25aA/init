# Оформление: GTK/Qt и курсор.
{ config, lib, pkgs, ... }:

lib.mkMerge [
  # GTK и Qt
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
      platformTheme.name = "qtct";

      qt5ctSettings.Appearance = {
        color_scheme_path = "${config.xdg.configHome}/qt6ct/colors/matugen.conf";
        custom_palette = true;
        icon_theme = "Papirus";
        style = "Fusion";
      };
      qt6ctSettings.Appearance = {
        color_scheme_path = "${config.xdg.configHome}/qt6ct/colors/matugen.conf";
        custom_palette = true;
        icon_theme = "Papirus";
        style = "Fusion";
      };
    };
  }

  # Курсор
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
