{ pkgs, lib, ... }:
let
  menu = pkgs.writeShellScriptBin "bspwm-clipboard" ''
    export PATH=${lib.makeBinPath [ pkgs.rofi pkgs.coreutils ]}:$PATH
    export CM_DIR="$XDG_RUNTIME_DIR" CM_LAUNCHER=rofi
    exec ${pkgs.clipmenu}/bin/clipmenu -p 'Буфер обмена'
  '';
in
{
  home.packages = [ pkgs.clipmenu menu ];
  systemd.user.services.bspwm-clipboard = {
    Unit = { Description = "Text clipboard history (bspwm only)"; PartOf = [ "bspwm-session.target" ]; };
    Service = {
      ExecStart = "${pkgs.clipmenu}/bin/clipmenud";
      Environment = [ "CM_DIR=%t" "CM_SELECTIONS=clipboard" ];
      Restart = "on-failure";
    };
    Install.WantedBy = [ "bspwm-session.target" ];
  };
}
