# bspwm: оконный менеджер, правила окон, пакеты для скриптов.
{ config, pkgs, ... }:

let
  xpkg = name: pkgs.${name} or pkgs.xorg.${name};

  inherit (import ./scripts.nix { inherit pkgs config; })
    monitors wallpaper autostart lock screenshot volume;
in

{
  home.packages = with pkgs; [
    monitors wallpaper autostart lock screenshot volume
    feh matugen maim xclip imagemagick i3lock-color
    playerctl wireplumber libnotify clipmenu
    (xpkg "xrandr") (xpkg "xsetroot") (xpkg "xrdb") libxcvt
  ];

  xresources.properties."Xft.dpi" = 96;

  xsession.windowManager.bspwm = {
    enable = true;
    extraConfigEarly = "${monitors}/bin/bspwm-monitors";

    settings = {
      border_width = 0;
      window_gap = 10;
      split_ratio = 0.5;
      automatic_scheme = "longest_side";
      initial_polarity = "second_child";
      removal_adjustment = true;
      borderless_monocle = true;
      gapless_monocle = false;
      single_monocle = false;
      focus_follows_pointer = true;
      pointer_follows_focus = false;
      pointer_follows_monitor = true;
      pointer_modifier = "mod4";
      pointer_action1 = "move";
      pointer_action2 = "resize_side";
      pointer_action3 = "resize_corner";
    };

    rules = {
      "Pavucontrol" = { state = "floating"; center = true; rectangle = "820x520+0+0"; };
      "pavucontrol" = { state = "floating"; center = true; rectangle = "820x520+0+0"; };
      "org.pulseaudio.pavucontrol" = { state = "floating"; center = true; rectangle = "820x520+0+0"; };
      "AmneziaVPN" = { state = "floating"; center = true; };
      "Thunar:*:File Operation Progress" = { state = "floating"; };
    };

    extraConfig = "${autostart}/bin/bspwm-autostart &";
  };
}
