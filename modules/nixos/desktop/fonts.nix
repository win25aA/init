# Шрифты.
{ pkgs, ... }:

{
  fonts.enableDefaultPackages = false;

  fonts.fontconfig.defaultFonts = {
    sansSerif = [ "DejaVu Sans" "Liberation Sans" ];
    serif     = [ "DejaVu Serif" "Liberation Serif" ];
    monospace = [ "DejaVu Sans Mono" "Liberation Mono" ];
    emoji     = [ "Noto Color Emoji" ];
  };

  fonts.packages = with pkgs; [
    dejavu_fonts
    freefont_ttf
    nerd-fonts.jetbrains-mono
    liberation_ttf
    unifont
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    corefonts
  ];
}
