{ config, pkgs, lib, ... }:
let
  start = pkgs.writeShellScript "bspwm-dunst" ''
    state="$HOME/.local/state/bspwm"
    ${pkgs.coreutils}/bin/mkdir -p "$state"
    ${pkgs.coreutils}/bin/cat ${config.xdg.configHome}/dunst/dunstrc > "$state/dunstrc"
    [ ! -r "$state/dunst-colors.conf" ] || ${pkgs.coreutils}/bin/cat "$state/dunst-colors.conf" >> "$state/dunstrc"
    exec ${pkgs.dunst}/bin/dunst -config "$state/dunstrc"
  '';
  history = pkgs.writeShellScriptBin "bspwm-notifications" ''
    export PATH=${lib.makeBinPath [ pkgs.dunst pkgs.jq pkgs.rofi pkgs.coreutils ]}:$PATH
    rows=$(dunstctl history | jq '
      walk(if type=="object" and has("type") and has("data") then .data else . end)
      | [.. | objects | select(has("id") and has("summary")) | {id, summary}]')
    choice=$({ printf '%s\n' 'Не беспокоить: переключить' 'Очистить историю';
      printf '%s' "$rows" | jq -r '.[] | .summary | gsub("[\\r\\n]"; " ")';
    } | rofi -dmenu -i -no-custom -format i -p 'Уведомления') || exit 0
    case "$choice" in
      0) dunstctl set-paused toggle ;;
      1)
        answer=$(printf 'Отмена\nДа\n' | rofi -dmenu -no-custom -p 'Очистить историю?') || exit 0
        [ "$answer" != Да ] || dunstctl history-clear
        ;;
      *) id=$(printf '%s' "$rows" | jq -r --argjson n "$((choice-2))" '.[$n].id'); dunstctl history-pop "$id" ;;
    esac
  '';
in
{
  home.packages = [ pkgs.dunst pkgs.libnotify history ];
  xdg.configFile."dunst/dunstrc".text = ''
    [global]
      monitor = 0
      follow = mouse
      origin = top-right
      offset = (20, 55)
      width = (250, 420)
      height = (0, 300)
      notification_limit = 5
      font = Maple Mono NF 10
      markup = full
      format = "<b>%s</b>\n%b"
      padding = 12
      horizontal_padding = 12
      frame_width = 2
      corner_radius = 10
      transparency = 8
      separator_height = 2
      history_length = 100
      sticky_history = yes
      show_age_threshold = 60
      mouse_left_click = do_action, close_current
      mouse_middle_click = close_all
      mouse_right_click = close_current
  '';
  systemd.user.services.bspwm-dunst = {
    Unit = {
      Description = "Dunst (bspwm only)";
      PartOf = [ "bspwm-session.target" ];
      After = [ "bspwm-wallpaper.service" ];
    };
    Service = { ExecStart = toString start; Restart = "on-failure"; };
    Install.WantedBy = [ "bspwm-session.target" ];
  };
}
