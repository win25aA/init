# GTK и Qt: тёмная adw-gtk3, иконки Papirus, цвета от matugen.
{ pkgs, ... }:

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
