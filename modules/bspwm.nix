{ config, lib, pkgs, ... }:
let
  nightTemperature = 4500;
  python = pkgs.python3.withPackages (p: [ p.pillow p.dbus-next p.python-xlib ]);
  polybar = pkgs.polybar.override { pulseSupport = true; };
  settings = pkgs.writeText "bspwm-desktop-settings.json" (builtins.toJSON {
    wallpaperDirectory = "/etc/nixos/wallpapers";
    defaultWallpaper = "/etc/nixos/wallpapers/wallpaperflare.com_wallpaper.jpg";
    latitude = 55.9122;
    longitude = 49.3128;
    # Ночной режим включён по умолчанию круглосуточно; температуру можно менять.
    inherit nightTemperature;
    compositorBackend = "glx"; # "xrender" is supported too (kernel blur).
    reduceMotion = false; # true disables window/menu animations.
  });
  cache = "${config.xdg.cacheHome}/bspwm";
  desktop = pkgs.writeShellApplication {
    name = "bspwm-desktop";
    runtimeInputs = with pkgs; [
      python bash coreutils procps util-linux bspwm xrandr xdotool xprop xev
      rofi feh matugen dunst libnotify picom polybar copyq flameshot
      kitty fish playerctl pulseaudio wireplumber xkb-switch brightnessctl
      pavucontrol networkmanagerapplet blueman zenity xdg-utils systemd i3lock
    ];
    text = ''
      export BSPWM_DESKTOP_SETTINGS=${settings}
      export LC_ALL=C.UTF-8
      export FLAMESHOT_CONFIG_PATH="${cache}/flameshot"
      exec ${python}/bin/python ${./desktop/desktop.py} "$@"
    '';
  };
  scoped = {
    PartOf = [ "bspwm-session.target" ];
    After = [ "graphical-session.target" ];
    ConditionEnvironment = "XDG_CURRENT_DESKTOP=bspwm";
  };
  unit = description: command: {
    Unit = scoped // { Description = description; };
    Service = {
      ExecStart = command;
      Restart = "on-failure";
      RestartSec = 2;
      Environment = [
        "PATH=${lib.makeBinPath [ desktop pkgs.bash pkgs.coreutils pkgs.rofi pkgs.playerctl pkgs.pavucontrol pkgs.dunst pkgs.xdg-utils pkgs.polybar pkgs.xrandr ]}:/run/current-system/sw/bin:/etc/profiles/per-user/${config.home.username}/bin"
        "FLAMESHOT_CONFIG_PATH=${cache}/flameshot"
      ];
    };
    Install.WantedBy = [ "bspwm-session.target" ];
  };
  # Если автоопределение ошиблось, впиши реальные имена из xrandr --query.
  mainOutput = "";
  secondOutput = "";

  detectOutputs = ''
    connected_outputs="$(${pkgs.xrandr}/bin/xrandr --query | ${pkgs.gawk}/bin/awk '$2 == "connected" { print $1 }')"
    pick_output() {
      for candidate in "$@"; do
        [ -n "$candidate" ] || continue
        [ "$candidate" != "''${main:-}" ] || continue
        if printf '%s\n' "$connected_outputs" | ${pkgs.gnugrep}/bin/grep -Fxq -- "$candidate"; then
          printf '%s\n' "$candidate"
          return 0
        fi
      done
      return 1
    }
    main=""
    main="$(pick_output ${lib.escapeShellArg mainOutput} DVI-D-0 DVI-D-1 DVI-I-0 DVI-I-1 DVI-0 DVI-1 || true)"
    if [ -z "$main" ]; then
      main="$(printf '%s\n' "$connected_outputs" | ${pkgs.coreutils}/bin/head -n 1)"
    fi
    second="$(pick_output ${lib.escapeShellArg secondOutput} HDMI-0 HDMI-1 HDMI-2 HDMI-A-1 HDMI-A-0 || true)"
  '';

  monitorLayout = pkgs.writeShellScript "bspwm-monitor-layout" ''
    ${detectOutputs}
    [ -n "$main" ] || exit 0
    # Не создаём непроверенные modeline: используем только режимы, известные Xorg.
    ${pkgs.xrandr}/bin/xrandr --output "$main" --primary --mode 1440x900 --rate 74.98 --pos 0x0 \
      || ${pkgs.xrandr}/bin/xrandr --output "$main" --primary --mode 1440x900 --pos 0x0 \
      || ${pkgs.xrandr}/bin/xrandr --output "$main" --primary --auto --pos 0x0
    if [ -n "$second" ]; then
      ${pkgs.xrandr}/bin/xrandr --output "$second" --mode 1024x768 --rate 70.07 --pos 1440x355 \
        || ${pkgs.xrandr}/bin/xrandr --output "$second" --mode 1024x768 --pos 1440x355 \
        || ${pkgs.xrandr}/bin/xrandr --output "$second" --auto --right-of "$main"
    fi
  '';

  scratchpad = pkgs.writeShellApplication {
    name = "bspwm-scratchpad";
    runtimeInputs = with pkgs; [ bspwm xdotool jq coreutils util-linux ];
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
        local id
        while read -r id; do
          [ -n "$id" ] || continue
          printf -v node '0x%x' "$id"
          if bspc query -T -n "$node" >/dev/null 2>&1; then
            printf '%s\n' "$node"
            return 0
          fi
        done < <(xdotool search --class "$pattern" 2>/dev/null || true)
        return 1
      }
      node="$(find_node || true)"
      if [ -z "$node" ]; then
        # Используем приложение из профиля, в т.ч. твой spotify-spotx.
        command -v "$app" >/dev/null || { echo "Not found: $app" >&2; exit 1; }
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

  desktopBindings = lib.listToAttrs (lib.concatMap (n:
    let
      key = if n == 10 then "0" else toString n;
      desktop = toString n;
    in [
      { name = "super + ${key}"; value = "bspc desktop -f ${desktop}"; }
      # Hyprland movetoworkspace переносил окно вместе с фокусом.
      { name = "super + ctrl + ${key}"; value = "bspc node -d ${desktop} --follow"; }
    ]
  ) (lib.range 1 10));
in
{
  home.packages = with pkgs; [
    desktop scratchpad kitty rofi dunst polybar copyq flameshot feh picom matugen
    xrandr xprop xdotool xev xset xsetroot xss-lock i3lock playerctl
    networkmanagerapplet blueman pavucontrol redshift conky
  ];
  home.keyboard = { layout = "us,ru"; options = [ "grp:alt_shift_toggle" ]; };
  home.pointerCursor = lib.mkDefault {
    enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };
  xdg.configFile."bspwm/main.rasi".text = builtins.replaceStrings [ "@CACHE@" ] [ cache ] (builtins.readFile ./desktop/main.rasi);
  xdg.configFile."bspwm/wallpapers.rasi".text = builtins.replaceStrings [ "@CACHE@" ] [ cache ] (builtins.readFile ./desktop/wallpapers.rasi);
  xdg.configFile."bspwm/polybar.ini".text = builtins.replaceStrings [ "@CACHE@" ] [ cache ] (builtins.readFile ./desktop/polybar.ini);
  xdg.configFile."rofi/config.rasi".text = ''
    configuration { modi: "drun,run,window"; show-icons: true; display-drun: "Приложения"; }
    @theme "${config.xdg.configHome}/bspwm/main.rasi"
  '';

  xsession = {
    enable = true;
    scriptPath = ".xsession-bspwm";
    profilePath = ".xprofile-bspwm";
    importedVariables = [ "XDG_SESSION_TYPE" "XDG_CURRENT_DESKTOP" "XDG_SESSION_DESKTOP" "FLAMESHOT_CONFIG_PATH" ];
    profileExtra = ''
      unset WAYLAND_DISPLAY NIXOS_OZONE_WL GBM_BACKEND WLR_NO_HARDWARE_CURSORS
      export XDG_SESSION_TYPE=x11
      export XDG_CURRENT_DESKTOP=bspwm
      export XDG_SESSION_DESKTOP=bspwm
      export _JAVA_AWT_WM_NONREPARENTING=1
      export FLAMESHOT_CONFIG_PATH="${cache}/flameshot"
      ${pkgs.systemd}/bin/systemctl --user unset-environment WAYLAND_DISPLAY NIXOS_OZONE_WL GBM_BACKEND WLR_NO_HARDWARE_CURSORS
      ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd DISPLAY XAUTHORITY XDG_SESSION_TYPE XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP FLAMESHOT_CONFIG_PATH
      ${monitorLayout}
    '';
    initExtra = ''
      ${pkgs.xsetroot}/bin/xsetroot -solid '#121212'
      ${desktop}/bin/bspwm-desktop bootstrap
      ${pkgs.systemd}/bin/systemctl --user start bspwm-session.target
      ${pkgs.xset}/bin/xset s 300 300
      ${pkgs.xset}/bin/xset +dpms
      ${pkgs.xset}/bin/xset dpms 600 600 600
      ${pkgs.xss-lock}/bin/xss-lock --transfer-sleep-lock -- ${desktop}/bin/bspwm-desktop lock &
      if command -v AmneziaVPN >/dev/null 2>&1; then AmneziaVPN & fi
    '';
    windowManager.bspwm = {
      enable = true;
      extraConfigEarly = ''
        ${detectOutputs}
        if [ -n "$main" ] && [ -n "$second" ]; then
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
        automatic_scheme = "longest_side";
        focus_follows_pointer = true;
        pointer_modifier = "mod4";
        pointer_action1 = "move";
        pointer_action2 = "none";
        pointer_action3 = "resize_corner";
      };
      rules = {
        "vesktop" = { state = "floating"; hidden = true; center = true; follow = false; focus = false; rectangle = "900x650+0+0"; };
        "Vesktop" = { state = "floating"; hidden = true; center = true; follow = false; focus = false; rectangle = "900x650+0+0"; };
        "spotify" = { state = "floating"; hidden = true; center = true; follow = false; focus = false; rectangle = "900x650+0+0"; };
        "Spotify" = { state = "floating"; hidden = true; center = true; follow = false; focus = false; rectangle = "900x650+0+0"; };
        "CopyQ" = { state = "floating"; center = true; };
        "copyq" = { state = "floating"; center = true; };
        "Conky" = { manage = false; };
        "flameshot" = { state = "floating"; border = false; };
        "Flameshot" = { state = "floating"; border = false; };
      };
    };
  };
  services.sxhkd = {
    enable = true;
    keybindings = desktopBindings // {
      "super + {Left,Right,Up,Down}" = "bspc node -f {west,east,north,south}";
      "super + button4" = "bspc desktop -f next.local";
      "super + button5" = "bspc desktop -f prev.local";
      "super + f" = "bspc node -t '~fullscreen'";
      "super + q" = "bspc node -c";
      "super + v" = "bspc node -t '~floating'";
      "super + m" = "${desktop}/bin/bspwm-desktop logout";
      "super + Tab" = "${pkgs.rofi}/bin/rofi -show window";
      "super + space" = "${pkgs.rofi}/bin/rofi -show drun";
      "super + shift + w" = "${desktop}/bin/bspwm-desktop wallpapers";
      "super + p" = "${desktop}/bin/bspwm-desktop session";
      "super + z" = "${desktop}/bin/bspwm-desktop control";
      "super + shift + s" = "${desktop}/bin/bspwm-desktop screenshot full";
      "super + ctrl + s" = "${desktop}/bin/bspwm-desktop screenshot region";
      "Print" = "${desktop}/bin/bspwm-desktop screenshot region";
      "super + Print" = "${desktop}/bin/bspwm-desktop screenshot monitor";
      "super + shift + v" = "${pkgs.copyq}/bin/copyq toggle";
      "super + n" = "${desktop}/bin/bspwm-desktop notifications";
      "super + shift + n" = "${pkgs.dunst}/bin/dunstctl set-paused toggle";
      "super + l" = "${desktop}/bin/bspwm-desktop lock";
      "super + shift + r" = "bspc wm -r";
      "super + button8" = "${pkgs.playerctl}/bin/playerctl previous";
      "super + button9" = "${pkgs.playerctl}/bin/playerctl next";
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
      "XF86AudioPlay" = "${pkgs.playerctl}/bin/playerctl play-pause";
      "XF86AudioNext" = "${pkgs.playerctl}/bin/playerctl next";
      "XF86AudioPrev" = "${pkgs.playerctl}/bin/playerctl previous";
      "XF86MonBrightnessUp" = "${pkgs.brightnessctl}/bin/brightnessctl set +5%";
      "XF86MonBrightnessDown" = "${pkgs.brightnessctl}/bin/brightnessctl set 5%-";
    };
  };

  # Unlike graphical-session.target, this target is only started by our X11 session.
  systemd.user.targets.bspwm-session.Unit = {
    Description = "Themed bspwm desktop";
    PartOf = [ "graphical-session.target" ];
    After = [ "graphical-session.target" ];
  };
  systemd.user.services = {
    bspwm-notification-archive = lib.recursiveUpdate (unit "Persistent notification archive" "${desktop}/bin/bspwm-desktop archive") {
      Service.Type = "notify";
      Service.TimeoutStartSec = 20;
    };
    bspwm-notifications = (unit "Themed X11 notifications" "${pkgs.dunst}/bin/dunst -conf ${cache}/dunstrc") // {
      Unit = scoped // {
        Description = "Themed X11 notifications";
        Wants = [ "bspwm-notification-archive.service" ];
        After = scoped.After ++ [ "bspwm-notification-archive.service" ];
      };
    };
    bspwm-polybar = unit "Noctalia-style Polybar" "${desktop}/bin/bspwm-desktop polybar";
    bspwm-picom = unit "X11 compositor" "${pkgs.picom}/bin/picom --config ${cache}/picom.conf";
    bspwm-copyq = lib.recursiveUpdate (unit "Clipboard history" "${pkgs.copyq}/bin/copyq") {
      Service.ExecStartPost = "${desktop}/bin/bspwm-desktop copyq-theme";
    };
    bspwm-flameshot = unit "Screenshot editor" "${pkgs.flameshot}/bin/flameshot";
    bspwm-osd = unit "Volume, microphone, layout and brightness OSD" "${desktop}/bin/bspwm-desktop osd-watch";
    bspwm-screen-corners = unit "Click-through screen corner masks" "${python}/bin/python ${./desktop/corners.py}";
    bspwm-weather-widget = unit "Weather desktop widget" "${pkgs.conky}/bin/conky --config=${cache}/conky.conf";
    bspwm-polkit = unit "Polkit authentication agent" "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
    bspwm-network-applet = unit "NetworkManager tray" "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator";
    bspwm-bluetooth-applet = unit "Bluetooth tray" "${pkgs.blueman}/bin/blueman-applet";
    bspwm-nightlight = lib.recursiveUpdate (unit "Night light enabled by default" "${pkgs.redshift}/bin/redshift -r -l 55.9122:49.3128 -t ${toString nightTemperature}:${toString nightTemperature} -m randr") {
      Unit.ConditionPathExists = "!${config.xdg.stateHome}/bspwm/nightlight-disabled";
      Service.ExecStopPost = "${pkgs.redshift}/bin/redshift -x -m randr";
    };
  };
}
