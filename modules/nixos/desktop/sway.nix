# SwayFX (системная часть). Пользовательский конфиг: modules/home/desktop/wayland/sway.
{ pkgs, ... }:

{
  programs.sway = {
    enable = true;
    package = pkgs.swayfx;
    wrapperFeatures.gtk = true;
    extraOptions = [ "--unsupported-gpu" ];
    extraSessionCommands = ''
      export WLR_NO_HARDWARE_CURSORS=1
      export LIBVA_DRIVER_NAME=nvidia
      export GBM_BACKEND=nvidia-drm
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export NVD_BACKEND=direct
      export XDG_CURRENT_DESKTOP=sway
      export XDG_SESSION_DESKTOP=sway
      export XDG_SESSION_TYPE=wayland
    '';
  };
}
