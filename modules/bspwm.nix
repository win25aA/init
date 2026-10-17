{ config, lib, pkgs, ... }:
let
  rofi = lib.getExe config.programs.rofi.package;
  # Xorg output names may differ from the names used by the Wayland compositors.
  detectOutputs = ''
    outputs="$(${pkgs.xrandr}/bin/xrandr --query | ${pkgs.gawk}/bin/awk '$2 == "connected" {print $1}')"
    main="$(printf '%s\n' "$outputs" | ${pkgs.gnugrep}/bin/grep -m1 -E '^DVI' || true)"
    [ -n "$main" ] || main="$(printf '%s\n' "$outputs" | ${pkgs.coreutils}/bin/head -n1)"
    second="$(printf '%s\n' "$outputs" | ${pkgs.gnugrep}/bin/grep -v -Fx "$main" | ${pkgs.coreutils}/bin/head -n1)"
  '';
  monitorLayout = pkgs.writeShellScript "bspwm-monitor-layout" ''
    ${detectOutputs}
    [ -n "$main" ] || exit 0
    ${pkgs.xrandr}/bin/xrandr --output "$main" --primary --mode 1440x900 --rate 74.98 --pos 0x0 \
      || ${pkgs.xrandr}/bin/xrandr --output "$main" --primary --auto --pos 0x0
    if [ -n "$second" ]; then
      ${pkgs.xrandr}/bin/xrandr --output "$second" --mode 1024x768 --rate 70.07 --pos 1440x355 \
        || ${pkgs.xrandr}/bin/xrandr --output "$second" --auto --right-of "$main"
    fi
  '';
  sessionMenu = pkgs.writeShellApplication {
    name = "bspwm-session-menu";
    runtimeInputs = [ config.programs.rofi.package pkgs.bspwm pkgs.systemd pkgs.i3lock ];
    text = ''
      choice="$(printf '%s\n' 'Lock' 'Log out' 'Suspend' 'Reboot' 'Power off' | rofi -dmenu -i -p Session)" || exit 0
      case "$choice" in
        Lock) i3lock -c 20252a ;;
        Suspend) systemctl suspend ;;
        'Log out'|Reboot|'Power off')
          confirm="$(printf '%s\n' Cancel Confirm | rofi -dmenu -i -p "$choice?")" || exit 0
          [ "$confirm" = Confirm ] || exit 0
          case "$choice" in
            'Log out') bspc quit ;;
            Reboot) systemctl reboot ;;
            'Power off') systemctl poweroff ;;
          esac ;;
      esac
    '';
  };
  wallpaper = pkgs.writeShellApplication {
    name = "bspwm-wallpaper";
    runtimeInputs = [ pkgs.zenity pkgs.feh pkgs.coreutils ];
    text = ''
      state="${config.xdg.stateHome}/bspwm/wallpaper"
      if [ "''${1:-}" = choose ]; then
        image="$(zenity --file-selection --title='Wallpaper' --filename=/etc/nixos/wallpapers/ --file-filter='Images | *.jpg *.jpeg *.png *.webp')" || exit 0
        [ -f "$image" ] || exit 1
        mkdir -p "$(dirname "$state")"
        printf '%s\n' "$image" > "$state"
      elif [ -f "$state" ]; then
        IFS= read -r image < "$state"
      else
        image=/etc/nixos/wallpapers/wallpaperflare.com_wallpaper.jpg
      fi
      [ -f "$image" ] || exit 0
      feh --no-fehbg --bg-fill "$image"
    '';
  };
  scratchpad = pkgs.writeShellApplication {
    name = "bspwm-scratchpad";
    runtimeInputs = [ pkgs.bspwm pkgs.xdotool pkgs.jq pkgs.coreutils pkgs.util-linux ];
    text = ''
      app="$1"
      case "$app" in
        vesktop) pattern='^[Vv]esktop$' ;;
        spotify) pattern='^[Ss]potify$' ;;
        *) exit 1 ;;
      esac
      exec 9>"$XDG_RUNTIME_DIR/bspwm-scratchpad-$app.lock"
      flock -n 9 || exit 0
      find_node() {
        local id node
        while read -r id; do
          printf -v node '0x%x' "$id"
          if bspc query -T -n "$node" >/dev/null 2>&1; then
            printf '%s\n' "$node"; return 0
          fi
        done < <(xdotool search --class "$pattern" 2>/dev/null || true)
        return 1
      }
      node="$(find_node || true)"
      if [ -z "$node" ]; then
        command -v "$app" >/dev/null || exit 1
        "$app" >"$XDG_RUNTIME_DIR/bspwm-$app.log" 2>&1 9>&- &
        for _ in $(seq 1 200); do
          node="$(find_node || true)"
          [ -z "$node" ] || break
          sleep 0.1
        done
        [ -n "$node" ] || exit 1
      fi
      if [ "$(bspc query -T -n "$node" | jq -r '.hidden')" = true ]; then
        bspc node "$node" -d focused
        bspc node "$node" -g hidden=off
        bspc node "$node" -f
      else
        bspc node "$node" -g hidden=on
      fi
    '';
  };
  workspaceBindings = lib.listToAttrs (lib.concatMap (n:
    let key = if n == 10 then "0" else toString n;
    in [
      { name = "super + ${key}"; value = "bspc desktop -f ${toString n}"; }
      { name = "super + ctrl + ${key}"; value = "bspc node -d ${toString n} --follow"; }
    ]) (lib.range 1 10));
in
{
  imports = [ ./bspwm/polybar.nix ./bspwm/services.nix ];
  home.packages = [
    sessionMenu wallpaper scratchpad pkgs.feh pkgs.playerctl pkgs.brightnessctl
    pkgs.pavucontrol pkgs.xrandr pkgs.xset pkgs.libnotify
  ];
  home.keyboard = { layout = "us,ru"; options = [ "grp:alt_shift_toggle" ]; };
  fonts.fontconfig.enable = true;

  programs.rofi = {
    enable = true;
    font = "Iosevka Nerd Font 12";
    terminal = "${lib.getExe pkgs.kitty}";
    settings = { modi = "drun,run,window"; show-icons = true; };
    theme = let inherit (config.lib.formats.rasi) mkLiteral; in {
      "*" = {
        background-color = mkLiteral "#20252a";
        text-color = mkLiteral "#b4bec8";
      };
      window = {
        width = mkLiteral "520px";
        border = mkLiteral "1px";
        border-color = mkLiteral "#080b0e";
        border-radius = mkLiteral "8px";
        padding = mkLiteral "14px";
      };
      mainbox = { spacing = mkLiteral "12px"; children = map mkLiteral [ "inputbar" "listview" ]; };
      inputbar = { children = map mkLiteral [ "prompt" "entry" ]; spacing = mkLiteral "10px"; };
      listview = { lines = 8; spacing = mkLiteral "4px"; };
      element = { padding = mkLiteral "8px"; border-radius = mkLiteral "4px"; };
      "element selected" = { background-color = mkLiteral "#39434c"; text-color = mkLiteral "#e0e6ec"; };
      element-text = { background-color = mkLiteral "inherit"; text-color = mkLiteral "inherit"; };
      element-icon = {
        size = mkLiteral "24px";
        margin = mkLiteral "0 8px 0 0";
        background-color = mkLiteral "inherit";
        text-color = mkLiteral "inherit";
      };
    };
  };

  xsession = {
    enable = true;
    scriptPath = ".xsession-bspwm";
    profilePath = ".xprofile-bspwm";
    importedVariables = [ "XDG_CURRENT_DESKTOP" "XDG_SESSION_DESKTOP" "XDG_SESSION_TYPE" ];
    profileExtra = ''
      # The global Wayland variables remain unchanged for the other sessions.
      unset WAYLAND_DISPLAY NIXOS_OZONE_WL GBM_BACKEND WLR_NO_HARDWARE_CURSORS
      export XDG_CURRENT_DESKTOP=bspwm XDG_SESSION_DESKTOP=bspwm XDG_SESSION_TYPE=x11
      ${pkgs.systemd}/bin/systemctl --user unset-environment WAYLAND_DISPLAY NIXOS_OZONE_WL GBM_BACKEND WLR_NO_HARDWARE_CURSORS
      ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd DISPLAY XAUTHORITY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE
      ${monitorLayout}
    '';
    # HM's sxhkd module starts a scope from initExtra; stop it before leaving X11.
    windowManager.command = lib.mkForce ''
      ${pkgs.bspwm}/bin/bspwm -c ${config.xdg.configHome}/bspwm/bspwmrc
      ${pkgs.systemd}/bin/systemctl --user stop sxhkd.scope
    '';
    windowManager.bspwm = {
      enable = true;
      extraConfigEarly = ''
        ${detectOutputs}
        if [ -n "$second" ]; then
          bspc monitor "$main" -d 1 2 3 4 5
          bspc monitor "$second" -d 6 7 8 9 10
        elif [ -n "$main" ]; then
          bspc monitor "$main" -d 1 2 3 4 5 6 7 8 9 10
        fi
      '';
      settings = {
        border_width = 0;
        window_gap = 10;
        split_ratio = 0.5;
        focus_follows_pointer = true;
        pointer_modifier = "mod4";
        pointer_action1 = "move";
        pointer_action2 = "none";
        pointer_action3 = "resize_corner";
      };
      rules = {
        "vesktop" = { state = "floating"; hidden = true; center = true; focus = false; };
        "Vesktop" = { state = "floating"; hidden = true; center = true; focus = false; };
        "spotify" = { state = "floating"; hidden = true; center = true; focus = false; };
        "Spotify" = { state = "floating"; hidden = true; center = true; focus = false; };
        "CopyQ" = { state = "floating"; center = true; };
        "copyq" = { state = "floating"; center = true; };
        "Pavucontrol" = { state = "floating"; center = true; };
        "flameshot" = { state = "floating"; border = false; };
      };
      extraConfig = ''
        ${wallpaper}/bin/bspwm-wallpaper
        ${pkgs.systemd}/bin/systemctl --user start bspwm-session.target
      '';
      startupPrograms = [
        ''${pkgs.procps}/bin/pgrep -u "$USER" -x AmneziaVPN >/dev/null || AmneziaVPN''
      ];
    };
  };

  services.sxhkd = {
    enable = true;
    keybindings = workspaceBindings // {
      "super + {Left,Right,Up,Down}" = "bspc node -f {west,east,north,south}";
      "super + button4" = "bspc desktop -f next.local";
      "super + button5" = "bspc desktop -f prev.local";
      "super + f" = "bspc node -t '~fullscreen'";
      "super + q" = "bspc node -c";
      "super + v" = "bspc node -t '~floating'";
      "super + m" = "${sessionMenu}/bin/bspwm-session-menu";
      "super + p" = "${sessionMenu}/bin/bspwm-session-menu";
      "super + space" = "${rofi} -show drun";
      "super + Tab" = "${rofi} -show window";
      "super + shift + w" = "${wallpaper}/bin/bspwm-wallpaper choose";
      "super + z" = "${lib.getExe pkgs.pavucontrol}";
      "super + shift + s" = "${lib.getExe pkgs.flameshot} full -c";
      "super + ctrl + s" = "${lib.getExe pkgs.flameshot} gui";
      "Print" = "${lib.getExe pkgs.flameshot} gui";
      "super + Print" = "${lib.getExe pkgs.flameshot} screen -c";
      "super + shift + v" = "${lib.getExe pkgs.copyq} toggle";
      "super + n" = "${pkgs.dunst}/bin/dunstctl history-pop";
      "super + shift + n" = "${pkgs.dunst}/bin/dunstctl set-paused toggle";
      "super + l" = "${pkgs.i3lock}/bin/i3lock -c 20252a";
      "super + shift + r" = "bspc wm -r";
      "super + button8" = "${lib.getExe pkgs.playerctl} previous";
      "super + button9" = "${lib.getExe pkgs.playerctl} next";
      "super + a" = "kitty";
      "super + e" = "thunar";
      "super + w" = "firefox";
      "super + t" = "AyuGram";
      "super + s" = "steam";
      "super + d" = "${scratchpad}/bin/bspwm-scratchpad vesktop";
      "super + c" = "${scratchpad}/bin/bspwm-scratchpad spotify";
      "XF86AudioRaiseVolume" = "${pkgs.wireplumber}/bin/wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+";
      "XF86AudioLowerVolume" = "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
      "XF86AudioMute" = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      "XF86AudioMicMute" = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
      "XF86AudioPlay" = "${lib.getExe pkgs.playerctl} play-pause";
      "XF86AudioNext" = "${lib.getExe pkgs.playerctl} next";
      "XF86AudioPrev" = "${lib.getExe pkgs.playerctl} previous";
      "XF86MonBrightnessUp" = "${lib.getExe pkgs.brightnessctl} set +5%";
      "XF86MonBrightnessDown" = "${lib.getExe pkgs.brightnessctl} set 5%-";
    };
  };
}
