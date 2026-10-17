{ config, pkgs, lib, ... }:
let
  polybar = pkgs.polybar.override { pulseSupport = true; mpdSupport = false; };
  media = pkgs.writeShellScriptBin "bspwm-media" ''
    state=$(${pkgs.playerctl}/bin/playerctl status 2>/dev/null || true)
    icon=
    [ "$state" != Playing ] || icon=
    printf '%%{T2}%%{A1:playerctl previous:}%%{A}%%{O7}%%{A1:playerctl play-pause:}%s%%{A}%%{O7}%%{A1:playerctl next:}%%{A}%%{T-}\n' "$icon"
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
  themeSwitcher = pkgs.writeShellScriptBin "polybar-theme" ''
    set -eu
    export PATH=${lib.makeBinPath [ pkgs.rofi pkgs.systemd pkgs.coreutils pkgs.util-linux pkgs.libnotify pkgs.matugen ]}:$PATH
    theme="''${1:-}"
    if [ -z "$theme" ]; then
      selected=0
      [ "$(cat "$HOME/.local/state/bspwm/polybar-theme" 2>/dev/null || true)" != silvia ] || selected=1
      theme=$(printf 'Varinka\nSilvia\n' | rofi -dmenu -i -no-custom -selected-row "$selected" -p 'Тема панели') || exit 0
    fi
    case "$theme" in
      Varinka|varinka) theme=varinka ;;
      Silvia|silvia) theme=silvia ;;
      *) printf 'Unknown Polybar theme: %s\n' "$theme" >&2; exit 2 ;;
    esac
    state="$HOME/.local/state/bspwm"
    mkdir -p "$state"
    exec 9> "$state/polybar-theme.lock"
    flock 9
    previous=varinka
    [ ! -r "$state/polybar-theme" ] || IFS= read -r previous < "$state/polybar-theme"
    # A freshly installed theme must use the CURRENT wallpaper, not bootstrap colors.
    # This also re-renders both palettes after a template change, without changing feh.
    if [ "''${XDG_SESSION_TYPE:-}" = x11 ] && [ "''${XDG_CURRENT_DESKTOP:-}" = bspwm ] && [ -r "$state/wallpaper" ]; then
      IFS= read -r image < "$state/wallpaper"
      if [ -f "$image" ]; then
        if ! matugen image "$image" --type scheme-content --source-color-index 0 >/dev/null; then
          notify-send -u critical Polybar 'Matugen не смог обновить палитру; тема не изменена.'
          exit 1
        fi
      fi
    fi
    printf '%s\n' "$theme" > "$state/polybar-theme.new"
    mv "$state/polybar-theme.new" "$state/polybar-theme"
    # Never start X11 services from Sway/Hyprland; save the choice for next login.
    if [ "''${XDG_SESSION_TYPE:-}" = x11 ] && [ "''${XDG_CURRENT_DESKTOP:-}" = bspwm ] && systemctl --user is-active --quiet bspwm-session.target; then
      if ! systemctl --user restart bspwm-polybar.service; then
        printf '%s\n' "$previous" > "$state/polybar-theme"
        systemctl --user restart bspwm-polybar.service || true
        notify-send -u critical Polybar 'Не удалось сменить тему; возвращена предыдущая.'
        exit 1
      fi
    fi
  '';
  launch = pkgs.writeShellScript "polybar-launch" ''
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
    theme=varinka
    [ ! -r "$state/polybar-theme" ] || IFS= read -r theme < "$state/polybar-theme"
    case "$theme" in
      silvia) panel=${config.xdg.configHome}/polybar/silvia/config.ini; bar=cata-bar ;;
      *) panel=${config.xdg.configHome}/polybar/varinka/config.ini; bar=varinka-bar ;;
    esac
    PRIMARY=""
    [ ! -r "$state/monitors.env" ] || . "$state/monitors.env"
    pids=()
    trap 'for pid in "''${pids[@]}"; do kill "$pid" 2>/dev/null || true; done' EXIT
    trap 'exit 0' TERM INT
    while IFS= read -r monitor; do
      [ -n "$monitor" ] || continue
      geometry=$(polybar --list-monitors | awk -v target="$monitor:" '$1 == target { print $2; exit }')
      width=''${geometry%%x*}
      title_length=24
      if [[ "$width" =~ ^[0-9]+$ ]] && [ "$width" -lt 1200 ]; then title_length=8; fi
      MONITOR="$monitor" VARINKA_TITLE_LENGTH="$title_length" polybar -c "$panel" "$bar" &
      pids+=("$!")
      sleep 0.5
    done < <({ [ -z "$PRIMARY" ] || echo "$PRIMARY"; polybar --list-monitors | cut -d: -f1; } | awk '!seen[$0]++')
    [ "''${#pids[@]}" -gt 0 ] || exit 1
    # One child dying must not leave the other monitor on a stale theme.
    wait -n "''${pids[@]}" || true
    exit 1
  '';
in
{
  home.packages = [ polybar media bluetooth updates themeSwitcher pkgs.jetbrains-mono pkgs.font-awesome pkgs.maple-mono.NF pkgs.nerd-fonts.symbols-only pkgs.playerctl pkgs.pavucontrol ];
  fonts.fontconfig.enable = true;
  xdg.configFile = {
    "polybar/varinka/config.ini".source = ./polybar/config.ini;
    "polybar/varinka/modules.ini".source = ./polybar/modules.ini;
    "polybar/silvia/config.ini".source = ./polybar/silvia/config.ini;
    "polybar/silvia/modules.ini".source = ./polybar/silvia/modules.ini;
  };
  systemd.user.services.bspwm-polybar = {
    Unit = {
      Description = "Original Varinka / Silvia Polybar on all monitors";
      PartOf = [ "bspwm-session.target" ];
      After = [ "bspwm-wallpaper.service" "bspwm-picom.service" ];
    };
    Service = { ExecStart = toString launch; Restart = "on-failure"; };
    Install.WantedBy = [ "bspwm-session.target" ];
  };
}
