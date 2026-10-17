{ config, pkgs, ... }:
{
  xdg.configFile."picom/picom.conf".text = ''
    backend = "glx";
    vsync = true;
    use-damage = true;
    shadow = true;
    shadow-radius = 8;
    shadow-opacity = 0.6;
    shadow-offset-x = 0;
    shadow-offset-y = 0;
    shadow-color = "#1a1a1a";
    fading = true;
    fade-in-step = 0.06;
    fade-out-step = 0.06;
    corner-radius = 10;
    blur-method = "dual_kawase";
    blur-strength = 3;
    blur-background = true;
    blur-background-frame = true;
    # Kitty already has opacity 0.6 in your config. Opaque apps are not forced transparent.
    # Polybar retains its own original 8px corner geometry and 35px height.
    rounded-corners-exclude = [
      "window_type = 'dock'",
      "window_type = 'desktop'",
      "class_g = 'i3lock'",
      "class_g = 'flameshot'"
    ];
    shadow-exclude = [
      "window_type = 'desktop'",
      "class_g = 'i3lock'",
      "class_g = 'flameshot'"
    ];
    blur-background-exclude = [
      "window_type = 'desktop'",
      "class_g = 'i3lock'",
      "class_g = 'flameshot'"
    ];
    unredir-if-possible = false;
  '';
  systemd.user.services.bspwm-picom = {
    Unit = { Description = "Picom (bspwm only)"; PartOf = [ "bspwm-session.target" ]; };
    Service = {
      ExecStart = "${pkgs.picom}/bin/picom --config ${config.xdg.configHome}/picom/picom.conf";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "bspwm-session.target" ];
  };
}
