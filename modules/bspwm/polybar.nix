{ config, lib, pkgs, ... }:
let
  # Fixed graphite palette from the reference, independent of Noctalia/Matugen.
  foreground = "#b4bec8";
  muted = "#65717c";
  player = lib.getExe pkgs.playerctl;
  rofi = lib.getExe config.programs.rofi.package;
  sep = { type = "custom/text"; content = "⠿"; content-foreground = muted; };
  bar = {
    monitor = "\${env:MONITOR:}";
    width = "100%:-28";
    height = "30px";
    offset-x = "14px";
    offset-y = "4px";
    radius = 8;
    background = "#ee20252a";
    inherit foreground;
    border-size = "1px";
    border-color = "#080b0e";
    line-size = "2px";
    padding-left = 1;
    padding-right = 1;
    module-margin = 1;
    font = [
      "Iosevka Nerd Font:style=Italic:size=10;2"
      "Iosevka Nerd Font:style=Bold:size=14;3"
      "Symbols Nerd Font Mono:size=11;2"
    ];
    modules-left = "launcher bspwm separator title";
    modules-right = "music previous play next separator filesystem cpu memory network separator date session";
    wm-restack = "bspwm";
    override-redirect = false;
    enable-ipc = true;
    cursor-click = "pointer";
    cursor-scroll = "ns-resize";
  };
in
{
  home.packages = [ pkgs.nerd-fonts.iosevka pkgs.nerd-fonts.symbols-only ];
  services.polybar = {
    enable = true;
    package = pkgs.polybar.override { pulseSupport = true; };
    # The HM module supervises the background children as one forking service.
    script = ''
      primary="$(${pkgs.xrandr}/bin/xrandr --query | ${pkgs.gawk}/bin/awk '$2 == "connected" && $3 == "primary" { print $1; exit }')"
      while IFS= read -r monitor; do
        [ -n "$monitor" ] || continue
        if [ "$monitor" = "$primary" ]; then
          MONITOR="$monitor" polybar main &
        else
          MONITOR="$monitor" polybar secondary &
        fi
      done < <(polybar --list-monitors | ${pkgs.coreutils}/bin/cut -d: -f1)
    '';
    settings = {
      "settings".screenchange-reload = true;
      "bar/main" = bar // {
        modules-right = "music previous play next volume separator filesystem cpu memory network tray separator date session";
      };
      # Fit the existing 1024px secondary screen without duplicating the XEmbed tray.
      "bar/secondary" = bar // {
        modules-right = "music previous play next volume separator cpu memory separator date session";
      };
      "module/launcher" = {
        type = "custom/text";
        content = "";
        content-font = 3;
        click-left = "${rofi} -show drun";
      };
      "module/bspwm" = {
        type = "internal/bspwm";
        pin-workspaces = true;
        enable-click = true;
        enable-scroll = true;
        reverse-scroll = false;
        format = "<label-state>";
        ws-icon = [ "1;A" "2;B" "3;C" "4;D" "5;E" "6;F" "7;G" "8;H" "9;I" "10;J" ];
        ws-icon-default = "•";
        label-focused = "%icon%";
        label-focused-font = 2;
        label-focused-foreground = "#e0e6ec";
        label-focused-padding = 1;
        label-occupied = "%icon%";
        label-occupied-font = 2;
        label-occupied-padding = 1;
        label-empty = "%icon%";
        label-empty-font = 2;
        label-empty-foreground = muted;
        label-empty-padding = 1;
        label-urgent = "%icon%";
        label-urgent-font = 2;
        label-urgent-foreground = "#d98e87";
        label-urgent-padding = 1;
      };
      "module/separator" = sep;
      "module/title" = {
        type = "internal/xwindow";
        label = "%title:0:22:…%";
        label-empty = "NixOS";
      };
      "module/music" = {
        type = "custom/text";
        content = "[ ";
        click-left = "${lib.getExe pkgs.kitty} -e ${lib.getExe pkgs.musikcube}";
      };
      "module/previous" = {
        type = "custom/text";
        content = "";
        click-left = "${player} previous";
      };
      "module/play" = {
        type = "custom/text";
        content = "";
        click-left = "${player} play-pause";
        click-right = "${player} stop";
      };
      "module/next" = {
        type = "custom/text";
        content = " ]";
        click-left = "${player} next";
      };
      "module/volume" = {
        type = "internal/pulseaudio";
        format-volume = " <label-volume>";
        label-volume = "%percentage%%";
        label-muted = "󰖁";
        label-muted-foreground = muted;
        click-right = "${lib.getExe pkgs.pavucontrol}";
      };
      "module/filesystem" = {
        type = "internal/fs";
        mount = [ "/" ];
        interval = 30;
        fixed-values = true;
        label-mounted = "󰋊 %free%";
      };
      "module/cpu" = {
        type = "internal/cpu";
        interval = 2;
        label = " %percentage%%";
      };
      "module/memory" = {
        type = "internal/memory";
        interval = 2;
        label = "󰍛 %gb_used%";
      };
      "module/network" = {
        type = "internal/network";
        interface-type = "wired";
        interval = 2;
        format-connected = "<label-connected>";
        label-connected = "󰇚 %downspeed:7% 󰕒 %upspeed:7%";
        label-disconnected = "󰖪";
        label-disconnected-foreground = muted;
      };
      "module/tray" = {
        type = "internal/tray";
        tray-size = "14px";
        tray-spacing = "4px";
      };
      "module/date" = {
        type = "internal/date";
        interval = 1;
        date = "%H:%M";
        date-alt = "%d.%m.%Y %H:%M";
        label = "%date%";
      };
      "module/session" = {
        type = "custom/text";
        content = "";
        click-left = "${config.home.profileDirectory}/bin/bspwm-session-menu";
        click-right = "${pkgs.i3lock}/bin/i3lock -c 20252a";
      };
    };
  };
}
