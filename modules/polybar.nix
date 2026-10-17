{ config, pkgs, lib, ... }:
let
  polybar = pkgs.polybar.override { pulseSupport = true; mpdSupport = false; };
  media = pkgs.writeShellScriptBin "bspwm-media" ''
    state=$(${pkgs.playerctl}/bin/playerctl status 2>/dev/null || true)
    icon=
    [ "$state" != Playing ] || icon=
    printf '%%{A1:playerctl previous:} %%{T2}%%{A}%%{A1:playerctl play-pause:} %%{T2}%s%%{A}%%{A1:playerctl next:} %%{T2}%%{A}%%{T-}\n' "$icon"
  '';
  bluetooth = pkgs.writeShellScriptBin "bspwm-bluetooth-status" ''
    if ${pkgs.bluez}/bin/bluetoothctl show 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q 'Powered: yes'; then
      echo 󰂯
    else
      echo 󰂲
    fi
  '';
  updates = pkgs.writeShellScriptBin "bspwm-updates" ''
    export PATH=${lib.makeBinPath [ pkgs.nix pkgs.jq pkgs.coreutils pkgs.libnotify pkgs.rofi ]}:$PATH
    state="$HOME/.local/state/bspwm"
    mkdir -p "$state"
    case "$1" in
      status) cat "$state/updates-status" 2>/dev/null || echo '?' ;;
      check)
        notify-send Nixpkgs 'Проверяю unstable без изменения flake.lock…'
        old=$(jq -r '.nodes[.nodes[.root].inputs.nixpkgs].locked.rev // empty' /etc/nixos/flake.lock 2>/dev/null || true)
        latest=$(nix flake metadata --json --refresh --no-write-lock-file github:NixOS/nixpkgs/nixos-unstable 2>/dev/null | jq -r '.locked.rev // empty')
        value='?'
        if [ -n "$old" ] && [ -n "$latest" ]; then
          value=↑; [ "$old" != "$latest" ] || value=0
        fi
        printf '%s\n' "$value" > "$state/updates-status"
        notify-send Nixpkgs "Результат: $value (0 — совпадает, ↑ — отличается, ? — ошибка)"
        ;;
      info) rofi -e '0 — совпадает с unstable; ↑ — ревизия отличается; ? — не проверено/ошибка. Это НЕ число пакетов. Проверка не обновляет систему.' ;;
    esac
  '';
  launch = pkgs.writeShellScript "polybar-varinka" ''
    export PATH=${lib.makeBinPath [ polybar pkgs.bspwm pkgs.iproute2 pkgs.jq pkgs.coreutils pkgs.gawk ]}:${config.home.profileDirectory}/bin:/run/current-system/sw/bin:$PATH
    state="$HOME/.local/state/bspwm"
    mkdir -p "$state"
    interface=$(ip -json route get 1.1.1.1 2>/dev/null | jq -r '.[0].dev // "lo"')
    [ -n "$interface" ] || interface=lo
    battery=BAT0; adapter=AC; backlight=none
    for device in /sys/class/power_supply/*; do
      [ -r "$device/type" ] || continue
      case "$(cat "$device/type")" in
        Battery) battery=$(basename "$device") ;;
        Mains) adapter=$(basename "$device") ;;
      esac
    done
    for device in /sys/class/backlight/*; do
      [ -e "$device" ] || continue
      backlight=$(basename "$device"); break
    done
    printf '[system]\nsys_network_interface = %s\nsys_battery = %s\nsys_adapter = %s\nsys_graphics_card = %s\n' \
      "$interface" "$battery" "$adapter" "$backlight" > "$state/system.ini"
    export VARINKA_SYSTEM="$state/system.ini" VARINKA_COLORS="$state/polybar-colors.ini"
    PRIMARY=""
    [ ! -r "$state/monitors.env" ] || . "$state/monitors.env"
    pids=()
    trap 'for pid in "''${pids[@]}"; do kill "$pid" 2>/dev/null || true; done' EXIT
    trap 'exit 0' TERM INT
    while IFS= read -r monitor; do
      [ -n "$monitor" ] || continue
      MONITOR="$monitor" polybar -c ${config.xdg.configHome}/polybar/varinka/config.ini varinka-bar &
      pids+=("$!")
      sleep 0.5
    done < <({ [ -z "$PRIMARY" ] || echo "$PRIMARY"; polybar --list-monitors | cut -d: -f1; } | awk '!seen[$0]++')
    wait
  '';
in
{
  home.packages = [ polybar media bluetooth updates pkgs.maple-mono.NF pkgs.playerctl pkgs.pavucontrol ];
  fonts.fontconfig.enable = true;
  xdg.configFile = {
    "polybar/varinka/config.ini".source = ./polybar/config.ini;
    "polybar/varinka/modules.ini".source = ./polybar/modules.ini;
  };
  systemd.user.services.bspwm-polybar = {
    Unit = {
      Description = "Original Varinka Polybar on all monitors";
      PartOf = [ "bspwm-session.target" ];
      After = [ "bspwm-wallpaper.service" ];
    };
    Service = { ExecStart = toString launch; Restart = "on-failure"; };
    Install.WantedBy = [ "bspwm-session.target" ];
  };
}
