# SwayFX (системная часть). Пользовательский конфиг: modules/home/desktop/wayland/sway.
{ config, lib, pkgs, ... }:

let
  nvidia = config.my.gpu == "nvidia";
in
{
  programs.sway = {
    enable = true;
    package = pkgs.swayfx;
    wrapperFeatures.gtk = true;
    extraOptions = lib.optional nvidia "--unsupported-gpu";
    extraSessionCommands = lib.optionalString nvidia ''
      export WLR_NO_HARDWARE_CURSORS=1
      export LIBVA_DRIVER_NAME=nvidia
      export GBM_BACKEND=nvidia-drm
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export NVD_BACKEND=direct
    '' + ''
      export XDG_CURRENT_DESKTOP=sway
      export XDG_SESSION_DESKTOP=sway
      export XDG_SESSION_TYPE=wayland
    '';
  };
}
