{ config, pkgs, lib, ... }:
let
  # User-editable settings. Empty connector names are detected by native mode.
  # Set exact X11 names here if detection is ambiguous (see `xrandr --query`).
  settings = {
    primaryOutput = "";
    secondaryOutput = "";
    primaryMode = "1440x900";
    primaryRate = "74.98";
    primaryPosition = "0x0";
    secondaryMode = "1024x768";
    secondaryRate = "70.07";
    secondaryPosition = "1440x355";
    wallpaperDirectory = "/etc/nixos/wallpapers";
    initialWallpaper = "/etc/nixos/wallpapers/wallpaperflare.com_wallpaper.jpg";
    screenshotDirectory = "${config.home.homeDirectory}/Pictures";
    configurationDirectory = "/etc/nixos";
    # Clipboard history stays in XDG_RUNTIME_DIR, not on persistent disk.
    clipboardHistory = true;
    # No new idle timeout is imposed. Sleep/manual locking is enabled.
    autoLockSeconds = 0;
  };
  polybar = pkgs.polybar.override {
    pulseSupport = true;
    mpdSupport = false; # Original MPD controls are adapted to playerctl/MPRIS.
  };
  runtime = with pkgs; [
    bspwm sxhkd rofi feh picom dunst libnotify flameshot playerctl
    clipmenu xsel xrandr xset setxkbmap xdotool xprop
    xss-lock i3lock-color redshift networkmanagerapplet networkmanager
    blueman pavucontrol pulseaudio wireplumber iproute2 bluez
    dbus util-linux procps coreutils bash kitty xdg-utils
    matugen nix python3
  ] ++ [ polybar ];
  varinka = pkgs.writeShellScriptBin "varinka" ''
    export PATH=${lib.makeBinPath runtime}:${config.home.profileDirectory}/bin:$PATH
    export VARINKA_ROOT=${./bspwm}
    export VARINKA_POLKIT_AGENT=${pkgs.lxqt.lxqt-policykit}/bin/lxqt-policykit-agent
    exec ${pkgs.python3}/bin/python3 ${./bspwm/varinka.py} "$@"
  '';
in
{
  home.packages = runtime ++ [ varinka pkgs.maple-mono.NF pkgs.lxqt.lxqt-policykit ];
  fonts.fontconfig.enable = true;

  # Deliberately DO NOT enable xsession.enable or services.sxhkd/dunst/picom:
  # NixOS starts this specific session; Sway/Hyprland autostarts remain untouched.
  xsession.windowManager.bspwm = {
    enable = true;
    monitors = { }; # Assigned safely by `varinka monitors`, without resetting on reload.
    settings = {
      border_width = 0;
      window_gap = 5;
      top_padding = 10; # Polybar's EWMH strut reserves the bar above this gap.
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
    extraConfigEarly = ''
      ${varinka}/bin/varinka monitors
    '';
    extraConfig = ''
      ${varinka}/bin/varinka reload-colors
      ${varinka}/bin/varinka session >> "$HOME/.local/state/varinka/session.log" 2>&1 &
    '';
  };

  xdg.configFile = {
    "bspwm/varinka/settings.json".text = builtins.toJSON settings;
    "sxhkd/sxhkdrc".source = ./bspwm/sxhkdrc;
    "polybar/varinka/config.ini".source = ./bspwm/polybar/config.ini;
    "polybar/varinka/modules.ini".source = ./bspwm/polybar/modules.ini;
    "matugen/varinka-colors.json".source = ./bspwm/templates/colors.json;
    "flameshot/flameshot.ini".text = ''
      [General]
      disabledTrayIcon=true
      showStartupLaunchMessage=false
      savePath=${settings.screenshotDirectory}
      savePathFixed=true
    '';
  };
  home.activation.varinkaState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "$HOME/.local/state/varinka" ${lib.escapeShellArg settings.screenshotDirectory}
    $DRY_RUN_CMD chmod 700 "$HOME/.local/state/varinka"
  '';
}
