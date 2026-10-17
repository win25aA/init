{ pkgs, ... }:
{
  # Minimal system-level integration: Xorg is already enabled in configuration.nix.
  # The explicit launcher clears Wayland-only variables BEFORE sxhkd/apps start.
  services.xserver.windowManager.session = [ {
    name = "bspwm-hm";
    start = ''
      unset WAYLAND_DISPLAY SWAYSOCK HYPRLAND_INSTANCE_SIGNATURE NIXOS_OZONE_WL
      unset GBM_BACKEND WLR_NO_HARDWARE_CURSORS
      export XDG_CURRENT_DESKTOP=bspwm
      export XDG_SESSION_DESKTOP=bspwm
      export XDG_SESSION_TYPE=x11
      unset QT_QPA_PLATFORM GDK_BACKEND SDL_VIDEODRIVER
      export _JAVA_AWT_WM_NONREPARENTING=1
      ${pkgs.systemd}/bin/systemctl --user unset-environment \
        WAYLAND_DISPLAY SWAYSOCK HYPRLAND_INSTANCE_SIGNATURE NIXOS_OZONE_WL GBM_BACKEND || true
      ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd \
        DISPLAY XAUTHORITY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE \
        NIXOS_OZONE_WL= WAYLAND_DISPLAY= SWAYSOCK= HYPRLAND_INSTANCE_SIGNATURE=
      # -m 1: use first keymap group, so Super+letter works with the RU layout.
      SXHKD_SHELL=${pkgs.bash}/bin/bash ${pkgs.sxhkd}/bin/sxhkd -m 1 &
      sxhkd_pid=$!
      ${pkgs.bspwm}/bin/bspwm &
      waitPID=$!
    '';
  } ];
  # i3lock-color uses the i3lock PAM service; no setuid workaround is needed.
  security.pam.services.i3lock = { };
  services.blueman.enable = true;
  xdg.portal.config.bspwm.default = [ "gtk" ];
}
