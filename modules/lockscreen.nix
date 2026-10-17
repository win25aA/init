{ pkgs, ... }:
let
  lock = pkgs.writeShellScriptBin "bspwm-lock" ''
    bg=212529; fg=f8f9fa; primary=dee2e6; muted=ced4da; error=dee2e6
    colors="$HOME/.local/state/bspwm/lock-colors.sh"
    [ ! -r "$colors" ] || . "$colors"
    # exec сохраняет XSS_SLEEP_LOCK_FD от xss-lock до захвата экрана i3lock.
    exec ${pkgs.i3lock-color}/bin/i3lock-color \
      --color "$bg" --clock --indicator --show-keyboard-layout \
      --time-str '%H:%M' --date-str '%d.%m.%Y' \
      --ring-color "''${primary}ff" --inside-color "''${bg}e8" \
      --time-color "''${fg}ff" --date-color "''${muted}ff" \
      --wrong-color "''${error}ff" "$@"
  '';
in
{
  home.packages = [ lock pkgs.i3lock-color pkgs.xss-lock ];
  systemd.user.services.bspwm-sleep-lock = {
    Unit = { Description = "Lock bspwm before sleep"; PartOf = [ "bspwm-session.target" ]; };
    Service.ExecStart = "${pkgs.xss-lock}/bin/xss-lock --transfer-sleep-lock -- ${lock}/bin/bspwm-lock --nofork";
    Install.WantedBy = [ "bspwm-session.target" ];
  };
}
