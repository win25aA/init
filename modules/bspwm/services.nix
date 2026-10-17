{ config, lib, pkgs, ... }:
let
  target = "bspwm-session.target";
  # Keep these native HM services out of Hyprland/Sway and stop them on logout.
  scoped = {
    Unit = {
      After = lib.mkForce [ "graphical-session.target" ];
      PartOf = lib.mkForce [ target ];
      ConditionEnvironment = "XDG_CURRENT_DESKTOP=bspwm";
    };
    Install.WantedBy = lib.mkForce [ target ];
  };
in
{
  services = {
    picom = {
      enable = true;
      backend = "glx";
      vSync = true;
      shadow = true;
      shadowOpacity = 0.3;
      shadowOffsets = [ (-4) (-4) ];
      shadowExclude = [ "window_type = 'dock'" "window_type = 'desktop'" ];
      fade = true;
      fadeDelta = 5;
      fadeSteps = [ 0.04 0.04 ];
      settings = {
        corner-radius = 8;
        detect-client-opacity = true;
        unredir-if-possible = false;
        rounded-corners-exclude = [ "window_type = 'dock'" "window_type = 'desktop'" ];
        # Polybar draws its own rounded shape; no screen-corner overlay.
        blur-method = "dual_kawase";
        blur-strength = 3;
        blur-background-exclude = [ "window_type = 'desktop'" ];
      };
    };
    dunst = {
      enable = true;
      settings = {
        global = {
          monitor = 0;
          follow = "mouse";
          width = 320;
          offset = "14x44";
          origin = "top-right";
          font = "Iosevka Nerd Font 11";
          frame_width = 1;
          frame_color = "#080b0e";
          corner_radius = 8;
          background = "#20252a";
          foreground = "#b4bec8";
          highlight = "#b4bec8";
          separator_color = "frame";
          padding = 12;
          horizontal_padding = 12;
          history_length = 100;
          indicate_hidden = true;
          format = "<b>%s</b>\\n%b";
          dmenu = "${lib.getExe config.programs.rofi.package} -dmenu -p Notifications";
        };
        urgency_low.timeout = 4;
        urgency_normal.timeout = 7;
        urgency_critical = { timeout = 0; frame_color = "#d98e87"; };
      };
    };
    copyq.enable = true;
    flameshot = {
      enable = true;
      settings.General = {
        showStartupLaunchMessage = false;
        uiColor = "#65717c";
        contrastUiColor = "#b4bec8";
        savePath = "${config.home.homeDirectory}/Pictures/Screenshots";
      };
    };
    network-manager-applet.enable = true;
    blueman-applet.enable = true;
    polkit-gnome.enable = true;
    redshift = {
      enable = true;
      provider = "manual";
      latitude = 55.9122;
      longitude = 49.3128;
      temperature = { day = 4500; night = 4500; };
      settings.redshift.adjustment-method = "randr";
    };
    screen-locker = {
      enable = true;
      lockCmd = "${pkgs.i3lock}/bin/i3lock -n -c 20252a";
      inactiveInterval = 5;
      xautolock.enable = false;
      xss-lock.extraOptions = [ "--transfer-sleep-lock" ];
    };
  };

  systemd.user.targets.bspwm-session.Unit = {
    Description = "Home Manager bspwm session";
    BindsTo = [ "graphical-session.target" ];
    After = [ "graphical-session.target" ];
  };
  systemd.user.services = lib.genAttrs [
    "polybar" "picom" "dunst" "copyq" "flameshot" "network-manager-applet"
    "blueman-applet" "polkit-gnome" "redshift" "xss-lock" "setxkbmap" "xplugd"
  ] (_: scoped);
}
