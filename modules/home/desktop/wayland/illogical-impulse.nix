# Оболочка end-4 для Hyprland. Sway по-прежнему использует Noctalia.
{ config, lib, pkgs, ... }:
let
  shell = pkgs.illogical-impulse;
  clipboardService = type: {
    Unit = {
      Description = "Clipboard history (${type}) for the Hyprland session";
      PartOf = [ "hyprland-session.target" ];
      After = [ "hyprland-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type ${type} --watch ${pkgs.cliphist}/bin/cliphist store";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };
in
{
  home.packages = [ shell ];
  # Только исходники интерфейса read-only. Личные настройки QS — обычный JSON.
  xdg.configFile."quickshell/ii".source = "${shell}/share/illogical-impulse";

  home.activation.seedIllogicalImpulse = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    export XDG_CONFIG_HOME=${lib.escapeShellArg config.xdg.configHome}
    export XDG_STATE_HOME=${lib.escapeShellArg config.xdg.stateHome}
    export II_DEFAULT_WALLPAPER="${shell}/share/illogical-impulse/assets/images/default_wallpaper.png"
    run ${shell}/bin/ii-seed-settings
  '';

  # Не запускаются в Sway/bspwm и останавливаются вместе с Hyprland.
  systemd.user.services.ii-clipboard-text = clipboardService "text";
  systemd.user.services.ii-clipboard-image = clipboardService "image";
}
