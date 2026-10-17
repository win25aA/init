{ config, pkgs, lib, ... }:
let
  screenshot = pkgs.writeShellScriptBin "bspwm-screenshot" ''
    set -eu
    export PATH=${lib.makeBinPath [ pkgs.flameshot pkgs.coreutils pkgs.file pkgs.libnotify ]}:$PATH
    umask 077
    directory="$HOME/Pictures"
    mkdir -p "$directory"
    temporary=$(mktemp "$directory/.screenshot-XXXXXX")
    trap 'rm -f "$temporary"' EXIT
    if [ "$1" = full ]; then
      flameshot full --raw > "$temporary" || exit 0
    else
      # Редактор области: подтвердить результат, отмена не создаёт PNG.
      flameshot gui --raw > "$temporary" || exit 0
    fi
    [ "$(file -b --mime-type "$temporary")" = image/png ] || exit 0
    destination="$directory/Screenshot_$(date +%Y-%m-%d_%H-%M-%S_%N).png"
    mv "$temporary" "$destination"
    notify-send 'Скриншот сохранён' "$destination"
  '';
in
{
  home.packages = [ pkgs.flameshot screenshot ];
  xdg.configFile."flameshot/flameshot.ini".text = ''
    [General]
    disabledTrayIcon=true
    showStartupLaunchMessage=false
    savePath=${config.home.homeDirectory}/Pictures
    savePathFixed=true
  '';
}
