# Экран входа SDDM с темой simple-sddm-2 (пакет: pkgs/simple-sddm-2-theme.nix).
{ pkgs, ... }:

{
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "simple-sddm-2";
    extraPackages = with pkgs.kdePackages; [
      qtmultimedia
      qtsvg
      qtvirtualkeyboard
    ];
  };

  environment.systemPackages = with pkgs; [
    simple-sddm-2-theme
  ];
}
