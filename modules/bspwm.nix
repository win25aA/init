# bspwm (X11) — порт моего Hyprland + всего, что было в noctalia.
# Панель — polybar из риса Isabel (gh0stzk/dotfiles, bar09).
# Все цвета (polybar, rofi, dunst, picom, локскрин, kitty/btop/gtk)
# генерирует matugen из текущих обоев.
{ config, lib, pkgs, ... }:

let
  src = ./bspwm;
  cfgHome = config.xdg.configHome;

  # xorg.* постепенно переезжает в корень nixpkgs — берём то, что есть
  xpkg = name: pkgs.${name} or pkgs.xorg.${name};

  # Шрифты панели Isabel: Inconsolata SemiCondensed, Material Design Icons Desktop,
  # Font Awesome 6 Free Solid (те же файлы, что в репозитории gh0stzk)
  gh0stzkRev = "793f584892f1041c7703be6a48faa018502dc27a";
  isabelFonts = pkgs.stdenvNoCC.mkDerivation {
    pname = "isabel-polybar-fonts";
    version = "1.0";
    dontUnpack = true;
    mdi = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/gh0stzk/dotfiles/${gh0stzkRev}/misc/fonts/MaterialDesignIconsDesktop.ttf";
      hash = "sha256-xcikoVf1OnCiJxbYC39NLfWioO6Sdz5AX3ym8lcsetM=";
    };
    fa = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/gh0stzk/dotfiles/${gh0stzkRev}/misc/fonts/FontAwesome6-Free-Solid.otf";
      hash = "sha256-HW7y2IjXd5EMk0WhWqQY1azH/Qv7iXlurrYQHW8O4nA=";
    };
    inconsolata = pkgs.fetchurl {
      name = "Inconsolata-variable.ttf";
      url = "https://raw.githubusercontent.com/google/fonts/0b58fb370093f9a9f4ff785d94405710b79de67c/ofl/inconsolata/Inconsolata%5Bwdth%2Cwght%5D.ttf";
      hash = "sha256-I97SW0RwdNAGWTkr+bESPYnfVcsHsK2b/vM2bRmbX8s=";
    };
    installPhase = ''
      install -Dm644 $mdi $out/share/fonts/truetype/MaterialDesignIconsDesktop.ttf
      install -Dm644 $fa $out/share/fonts/opentype/FontAwesome6-Free-Solid.otf
      install -Dm644 $inconsolata $out/share/fonts/truetype/Inconsolata-Variable.ttf
    '';
  };

  deps = with pkgs; [
    coreutils gnugrep gnused gawk findutils procps util-linux
    picom polybarFull rofi dunst libnotify
    feh matugen maim xclip imagemagick i3lock-color xdotool jq
    playerctl wireplumber pavucontrol gammastep clipmenu
    (xpkg "xrandr") (xpkg "xsetroot")
  ];

  # Скрипты лежат в modules/bspwm/scripts/*.sh
  # (скрипты вызывают друг друга по имени, поэтому в PATH и профиль пользователя)
  mkScript = name: pkgs.writeShellScriptBin name ''
    export PATH="${lib.makeBinPath deps}:${config.home.profileDirectory}/bin:/run/current-system/sw/bin:$PATH"
    export POLKIT_AGENT="${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
    ${withPaths (src + "/scripts/${name}.sh")}
  '';

  scripts = map mkScript [
    "bspwm-monitors"
    "bspwm-autostart"
    "bspwm-wallpaper"
    "bspwm-wallpaper-menu"
    "bspwm-screenshot"
    "bspwm-volume"
    "bspwm-lock"
    "polybar-launch"
    "polybar-media"
    "polybar-notify"
    "rofi-power"
    "rofi-control"
    "rofi-notifications"
  ];

  # подставляем абсолютные пути (файлы из стора не видят друг друга по относительным путям)
  withPaths = file: builtins.replaceStrings [ "@CONFIG@" ] [ cfgHome ] (builtins.readFile file);
in
{
  home.packages = deps ++ scripts ++ [ isabelFonts ];
  fonts.fontconfig.enable = true;

  # ---------------------------------------------------------------- bspwm
  xsession.windowManager.bspwm = {
    enable = true;

    # мониторы: имена выходов на X11 ищутся автоматически (см. скрипт)
    extraConfigEarly = "bspwm-monitors";

    settings = {
      border_width = 0;              # как в Hyprland: рамок нет
      window_gap = 10;               # gaps_in 5 + 5 / gaps_out 10
      split_ratio = 0.5;
      automatic_scheme = "longest_side";   # похоже на dwindle
      initial_polarity = "second_child";
      removal_adjustment = true;
      borderless_monocle = true;
      gapless_monocle = false;
      single_monocle = false;
      focus_follows_pointer = true;
      pointer_follows_focus = false;
      pointer_follows_monitor = true;
      # Super + ЛКМ — двигать, Super + ПКМ — менять размер
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

    extraConfig = "bspwm-autostart &";
  };

  # ---------------------------------------------------------------- хоткеи
  services.sxhkd = {
    enable = true;
    keybindings = {
      # воркспейсы (1–5 — основной монитор, 6–10 — второй)
      "super + {1-9,0}" = "bspc desktop -f {1-9,10}";
      "super + ctrl + {1-9,0}" = "bspc node -d {1-9,10} --follow";
      "super + {button4,button5}" = "bspc desktop -f {next,prev}.local.occupied";

      # навигация
      "super + {Left,Right,Up,Down}" = "bspc node -f {west,east,north,south}";
      "super + shift + {Left,Right,Up,Down}" = "bspc node -s {west,east,north,south}";

      # окна
      "super + f" = "bspc node -t ~fullscreen";
      "super + q" = "bspc node -c";
      "super + v" = "bspc node -t ~floating";
      "super + m" = "bspc quit";

      # то, что было в noctalia
      "super + space" = "rofi -show drun";
      "super + shift + w" = "bspwm-wallpaper-menu";
      "super + p" = "rofi-power";
      "super + z" = "rofi-control";
      "super + shift + s" = "bspwm-screenshot full";
      "super + ctrl + s" = "bspwm-screenshot region";
      "super + l" = "bspwm-lock";

      # плеер на боковых кнопках мыши (как mouse:275/276 в Hyprland)
      "super + button8" = "playerctl previous";
      "super + button9" = "playerctl next";

      # громкость с OSD
      "XF86AudioRaiseVolume" = "bspwm-volume up";
      "XF86AudioLowerVolume" = "bspwm-volume down";
      "XF86AudioMute" = "bspwm-volume mute";

      # приложения
      "super + a" = "kitty";
      "super + e" = "thunar";
      "super + w" = "firefox";
      "super + t" = "AyuGram";
      "super + s" = "steam";
      "super + d" = "vesktop";
      "super + c" = "spotify";

      # перезагрузка конфигов
      "super + Escape" = "pkill -USR1 -x sxhkd && notify-send 'sxhkd' 'Хоткеи перезагружены'";
      "super + alt + r" = "bspc wm -r";
    };
  };

  # ---------------------------------------------------------------- конфиги
  xdg.configFile = {
    "polybar/config.ini".text = withPaths (src + "/polybar/config.ini");
    "polybar/modules.ini".source = src + "/polybar/modules.ini";
    "picom/picom.conf".text = withPaths (src + "/picom.conf");
    "rofi/config.rasi".text = withPaths (src + "/rofi/config.rasi");

    # шаблоны matugen
    "matugen/bspwm/polybar-colors.ini".source = src + "/matugen/polybar-colors.ini";
    "matugen/bspwm/rofi-colors.rasi".source = src + "/matugen/rofi-colors.rasi";
    "matugen/bspwm/dunstrc".source = src + "/matugen/dunstrc";
    "matugen/bspwm/picom-colors.conf".source = src + "/matugen/picom-colors.conf";
    "matugen/bspwm/lock-colors.sh".source = src + "/matugen/lock-colors.sh";

    # дописываем шаблоны к существующему matugen/config.toml из matugen.nix
    "matugen/config.toml".text = lib.mkAfter ''

      # --- bspwm / X11 ---
      [templates.polybar]
      input_path = "~/.config/matugen/bspwm/polybar-colors.ini"
      output_path = "~/.config/polybar/colors.ini"

      [templates.rofi]
      input_path = "~/.config/matugen/bspwm/rofi-colors.rasi"
      output_path = "~/.config/rofi/colors.rasi"

      [templates.dunst]
      input_path = "~/.config/matugen/bspwm/dunstrc"
      output_path = "~/.config/dunst/dunstrc"

      [templates.picom]
      input_path = "~/.config/matugen/bspwm/picom-colors.conf"
      output_path = "~/.config/picom/colors.conf"

      [templates.lockscreen]
      input_path = "~/.config/matugen/bspwm/lock-colors.sh"
      output_path = "~/.config/bspwm/lock-colors.sh"
    '';
  };
}
