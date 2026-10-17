{ config, pkgs, lib, ... }:
let
  audio = pkgs.writeShellScriptBin "bspwm-audio" ''
    export PATH=${lib.makeBinPath [ pkgs.wireplumber pkgs.libnotify pkgs.gawk ]}:$PATH
    device=@DEFAULT_AUDIO_SINK@
    title=Громкость
    case "$1" in
      up) wpctl set-volume -l 1.5 "$device" '5%+' ;;
      down) wpctl set-volume "$device" '5%-' ;;
      mute) wpctl set-mute "$device" toggle ;;
      mic) device=@DEFAULT_AUDIO_SOURCE@; title=Микрофон; wpctl set-mute "$device" toggle ;;
    esac
    value=$(wpctl get-volume "$device")
    level=$(printf '%s\n' "$value" | awk '{ printf "%d", $2*100 }')
    label="$level%"
    case "$value" in *MUTED*) label=Выключено ;; esac
    notify-send -a bspwm -h string:x-dunst-stack-tag:volume -h "int:value:$level" "$title" "$label"
  '';
in
{
  home.packages = [ pkgs.sxhkd audio ];
  xdg.configFile."sxhkd/sxhkdrc".text = ''
    super + {1-9,0}
        bspc desktop -f '{1-9,10}'
    super + ctrl + {1-9,0}
        bspc node -d '{1-9,10}' --follow
    super + {Left,Right,Up,Down}
        bspc node -f {west,east,north,south}
    super + f
        bspc node -t ~fullscreen
    super + q
        bspc node -c
    super + v
        bspc node -t ~floating
    super + m
        desktop-menu exit
    super + shift + c
        bash ~/.config/bspwm/bspwmrc; pkill -USR1 -u "$(id -u)" -x sxhkd
    super + space
        desktop-menu launcher
    super + shift + w
        choose-wallpaper
    super + p
        desktop-menu session
    super + z
        desktop-menu control
    super + shift + s
        bspwm-screenshot full
    super + ctrl + s
        bspwm-screenshot region
    super + {a,e,w,t,s,d,c}
        {kitty,thunar,firefox,AyuGram,steam,vesktop,spotify}
    super + button4
        bspc desktop -f prev.local
    super + button5
        bspc desktop -f next.local
    super + button8
        playerctl previous
    super + button9
        playerctl next
    super + l
        bspwm-lock
    super + shift + v
        bspwm-clipboard
    super + n
        bspwm-notifications
    XF86AudioRaiseVolume
        bspwm-audio up
    XF86AudioLowerVolume
        bspwm-audio down
    XF86AudioMute
        bspwm-audio mute
    XF86AudioMicMute
        bspwm-audio mic
    XF86AudioPlay
        playerctl play-pause
    XF86AudioPrev
        playerctl previous
    XF86AudioNext
        playerctl next
  '';
  systemd.user.services.bspwm-sxhkd = {
    Unit = { Description = "sxhkd (bspwm only)"; PartOf = [ "bspwm-session.target" ]; };
    Service = {
      ExecStart = "${pkgs.sxhkd}/bin/sxhkd -m 1 -c ${config.xdg.configHome}/sxhkd/sxhkdrc";
      Environment = [
        "SXHKD_SHELL=${pkgs.bash}/bin/bash"
        "PATH=${lib.makeBinPath [ pkgs.bspwm pkgs.playerctl pkgs.bash pkgs.procps pkgs.coreutils ]}:${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
      ];
      Restart = "on-failure";
    };
    Install.WantedBy = [ "bspwm-session.target" ];
  };
}
