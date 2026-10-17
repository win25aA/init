{ config, pkgs, lib, ... }:
let
  directory = "/etc/nixos/wallpapers";
  initial = "/etc/nixos/wallpapers/wallpaperflare.com_wallpaper.jpg";
  setWallpaper = pkgs.writeShellScriptBin "set-wallpaper" ''
    set -eu
    export PATH=${lib.makeBinPath [ pkgs.matugen pkgs.feh pkgs.util-linux pkgs.coreutils pkgs.libnotify ]}:${config.home.profileDirectory}/bin:$PATH
    state="$HOME/.local/state/bspwm"
    mkdir -p "$state"
    if [ "$1" = --restore ]; then
      image=${lib.escapeShellArg initial}
      [ ! -r "$state/wallpaper" ] || IFS= read -r image < "$state/wallpaper"
      [ -f "$image" ] || exit 0
    else
      image=$(realpath -- "$1")
    fi
    [ -f "$image" ] || exit 1
    exec 9> "$state/wallpaper.lock"
    flock 9
    # При ошибке Matugen картинка не меняется. Флаги — как в твоём Noctalia.
    matugen image "$image" --type scheme-content --source-color-index 0
    feh --no-fehbg --bg-fill "$image"
    printf '%s\n' "$image" > "$state/wallpaper.new"
    mv "$state/wallpaper.new" "$state/wallpaper"
    [ "$1" = --restore ] || notify-send 'Обои и Matugen' "$(basename "$image")"
  '';
  chooser = pkgs.writeShellScriptBin "choose-wallpaper" ''
    export PATH=${lib.makeBinPath [ pkgs.findutils pkgs.coreutils pkgs.rofi ]}:$PATH
    mapfile -d "" files < <(find ${lib.escapeShellArg directory} -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.bmp' \) -print0 | sort -z)
    [ "''${#files[@]}" -gt 0 ] || exit 0
    selection=$(
      for path in "''${files[@]}"; do
        name=$(basename "$path")
        name=''${name//$'\n'/ }
        printf '%s\0icon\x1f%s\n' "$name" "$path"
      done | rofi -dmenu -i -no-custom -format i -p 'Обои' \
        -theme-str 'window { width: 900px; } listview { columns: 3; lines: 3; } element { orientation: vertical; } element-icon { size: 160px; }'
    ) || exit 0
    [[ "$selection" =~ ^[0-9]+$ ]] || exit 0
    ${setWallpaper}/bin/set-wallpaper "''${files[$selection]}"
  '';
in
{
  home.packages = [ setWallpaper chooser pkgs.feh ];
  systemd.user.services.bspwm-wallpaper = {
    Unit = { Description = "Restore wallpaper and Matugen (bspwm)"; PartOf = [ "bspwm-session.target" ]; };
    Service = { Type = "oneshot"; ExecStart = "${setWallpaper}/bin/set-wallpaper --restore"; RemainAfterExit = true; };
    Install.WantedBy = [ "bspwm-session.target" ];
  };
}
