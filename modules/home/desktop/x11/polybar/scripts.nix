# polybar: скрипты запуска бара, плеера и уведомлений.
{ pkgs, ... }:

let
  launch = pkgs.writeShellScriptBin "polybar-launch" ''

    pkill -x polybar
    while pgrep -x polybar >/dev/null; do sleep 0.1; done

    primary=$(xrandr --query | awk '/ connected primary/ { print $1; exit }')
    mapfile -t mons < <(polybar --list-monitors | cut -d: -f1)
    [ -z "$primary" ] && primary=''${mons[0]}

    for m in "''${mons[@]}"; do
      if [ "$m" = "$primary" ]; then
        MONITOR=$m setsid -f polybar -q isa-bar >/dev/null 2>&1
      else
        MONITOR=$m setsid -f polybar -q isa-bar-secondary >/dev/null 2>&1
      fi
    done
  '';

  media = pkgs.writeShellScriptBin "polybar-media" ''

    playerctl --follow metadata --format '{{status}}|||{{artist}}|||{{title}}' 2>/dev/null |
    while IFS= read -r line; do
      status=''${line%%|||*}; rest=''${line#*|||}
      artist=''${rest%%|||*}; title=''${rest#*|||}
      if [ -z "$title" ] || [ "$status" = "Stopped" ] || [ "$line" = "$rest" ]; then
        echo ""
      elif [ -n "$artist" ]; then
        printf '%s - %s\n' "$artist" "$title"
      else
        printf '%s\n' "$title"
      fi | sed 's/%{/%%{/g'
    done

    echo ""
    sleep 5
  '';

  notify = pkgs.writeShellScriptBin "polybar-notify" ''

    if [ "$(dunstctl is-paused 2>/dev/null)" = "true" ]; then
      echo "%{T4}"$'\uf1f6'"%{T-}"
    else
      n=$(dunstctl count history 2>/dev/null || echo 0)
      if [ "''${n:-0}" -gt 0 ]; then echo "%{T4}"$'\uf0f3'"%{T-} $n"; else echo "%{T4}"$'\uf0f3'"%{T-}"; fi
    fi
  '';
in
{
  home.packages = [ launch media notify ];
}
