{ config, pkgs, lib, ... }:
let
  # Названия выходов X11 уточни через xrandr --query.
  # Пустое значение: поиск по поддерживаемому разрешению.
  primaryOutput = "";
  secondaryOutput = "";
  monitors = pkgs.writeShellScript "bspwm-monitors" ''
    export PATH=${lib.makeBinPath [ pkgs.bspwm pkgs.xrandr pkgs.gawk pkgs.coreutils pkgs.gnugrep ]}:$PATH
    set -eu
    state="$HOME/.local/state/bspwm"
    mkdir -p "$state"
    query=$(xrandr --query)
    connected() { printf '%s\n' "$query" | awk '/ connected/ { print $1 }'; }
    detect() {
      printf '%s\n' "$query" | awk -v mode="$1" -v skip="$2" '
        /^[^ ]/ { output = ($2 == "connected" ? $1 : "") }
        output != "" && output != skip && $1 == mode { print output; exit }'
    }
    primary=${lib.escapeShellArg primaryOutput}
    secondary=${lib.escapeShellArg secondaryOutput}
    [ -n "$primary" ] || primary=$(detect 1440x900 "")
    [ -n "$primary" ] || primary=$(connected | head -n1)
    [ -n "$primary" ] || { echo 'No connected X11 output' >&2; exit 1; }
    [ -n "$secondary" ] || secondary=$(detect 1024x768 "$primary")
    configure() {
      local output="$1" mode="$2" requested="$3" position="$4"
      local rate
      connected | grep -Fxq "$output" || return 1
      rate=$(printf '%s\n' "$query" | awk -v output="$output" -v mode="$mode" -v requested="$requested" '
        /^[^ ]/ { active = ($1 == output && $2 == "connected") }
        active && $1 == mode {
          for (i=2; i<=NF; i++) {
            gsub(/[*+]/, "", $i); delta=$i-requested; if (delta<0) delta=-delta;
            if (delta<0.3) { print $i; exit }
          }
        }')
      local args=(--output "$output" --pos "$position")
      if printf '%s\n' "$query" | awk -v output="$output" -v mode="$mode" '
          /^[^ ]/ { active = ($1 == output && $2 == "connected") }
          active && $1 == mode { found=1 } END { exit !found }'; then
        args+=(--mode "$mode")
        [ -z "$rate" ] || args+=(--rate "$rate")
      else
        echo "$output: mode $mode unavailable; using --auto, no custom modeline" >&2
        args+=(--auto)
      fi
      [ "$output" != "$primary" ] || args+=(--primary)
      xrandr "''${args[@]}"
    }
    configure "$primary" 1440x900 74.98 0x0
    [ -z "$secondary" ] || configure "$secondary" 1024x768 70.07 1440x355
    for attempt in $(seq 1 30); do
      known=$(bspc query -M --names)
      if printf '%s\n' "$known" | grep -Fxq "$primary"; then
        if [ -z "$secondary" ] || printf '%s\n' "$known" | grep -Fxq "$secondary"; then break; fi
      fi
      sleep 0.1
    done
    assign() {
      local output="$1"; shift
      local number id first
      for number in "$@"; do
        id=$(bspc query -D -d "$number" 2>/dev/null || true)
        if [ -n "$id" ]; then
          bspc desktop "$id" -m "$output" 2>/dev/null || true
        elif [ "$(bspc query -D -m "$output" --names)" = Desktop ]; then
          first=$(bspc query -D -m "$output" | head -n1)
          bspc desktop "$first" -n "$number"
        else
          bspc monitor "$output" -a "$number"
        fi
      done
    }
    if [ -n "$secondary" ]; then
      assign "$primary" 1 2 3 4 5
      assign "$secondary" 6 7 8 9 10
    else
      assign "$primary" 1 2 3 4 5 6 7 8 9 10
    fi
    printf 'PRIMARY=%q\nSECONDARY=%q\n' "$primary" "$secondary" > "$state/monitors.env"
  '';
  service = command: {
    Unit = { PartOf = [ "bspwm-session.target" ]; };
    Service = { ExecStart = command; Restart = "on-failure"; };
    Install.WantedBy = [ "bspwm-session.target" ];
  };
in
{
  home.packages = with pkgs; [ bspwm xrandr setxkbmap xset networkmanagerapplet blueman lxqt.lxqt-policykit ];
  xsession.windowManager.bspwm = {
    enable = true;
    monitors = { };
    extraConfigEarly = ''
      ${monitors}
      ${pkgs.xsetroot}/bin/xsetroot -cursor_name left_ptr
      ${pkgs.setxkbmap}/bin/setxkbmap -layout us,ru -option "" -option grp:alt_shift_toggle
    '';
    settings = {
      border_width = 0;
      window_gap = 5;
      top_padding = 10;
      bottom_padding = 10;
      left_padding = 10;
      right_padding = 10;
      split_ratio = 0.5;
      focus_follows_pointer = false;
      pointer_follows_focus = false;
      pointer_modifier = "mod4";
      pointer_action1 = "move";
      pointer_action2 = "resize_side";
      pointer_action3 = "resize_corner";
      remove_disabled_monitors = true;
      remove_unplugged_monitors = true;
      merge_overlapping_monitors = true;
      honor_size_hints = true;
    };
    rules = {
      "Pavucontrol" = { state = "floating"; center = true; };
      "Blueman-manager" = { state = "floating"; center = true; };
      "Nm-connection-editor" = { state = "floating"; center = true; };
      "flameshot" = { state = "floating"; };
    };
    extraConfig = ''
      [ ! -r "$HOME/.local/state/bspwm/bspwm-colors.sh" ] || . "$HOME/.local/state/bspwm/bspwm-colors.sh"
      # Автоматический таймаут блокировки не навязываем; ручная/перед сном включена.
      ${pkgs.xset}/bin/xset s 0
      ${pkgs.systemd}/bin/systemctl --user start bspwm-session.target
    '';
  };
  systemd.user.targets.bspwm-session.Unit = {
    Description = "User services for bspwm only";
    PartOf = [ "graphical-session.target" ];
  };
  systemd.user.services = {
    bspwm-network = service "${pkgs.networkmanagerapplet}/bin/nm-applet";
    bspwm-bluetooth = service "${pkgs.blueman}/bin/blueman-applet";
    bspwm-polkit = service "${pkgs.lxqt.lxqt-policykit}/bin/lxqt-policykit-agent";
    bspwm-vpn = service (toString (pkgs.writeShellScript "bspwm-vpn" ''
      export PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin:$PATH
      command -v AmneziaVPN >/dev/null || exit 0
      exec AmneziaVPN
    ''));
  };
}
