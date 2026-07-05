{ config, pkgs, ... }:

let
  ipc = "noctalia msg";
  esc = builtins.fromJSON ''"\u001b"'';
in
{
  home.stateVersion = "26.11";

  home.packages = with pkgs; [
    htop
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    xwayland.enable = true;

    configType = "hyprlang";

    settings = {
      monitor = [
        "DVI-D-1,1440x900@74.98,0x0,1"
        "HDMI-A-1,1024x768@70.07,1440x355,1"
      ];

      input = {
        kb_layout = "us,ru";
        kb_options = "grp:alt_shift_toggle";
      };

      general = {
        "col.active_border" = "rgba(00000000)";
        "col.inactive_border" = "rgba(00000000)";
        gaps_in = 5;
        gaps_out = 10;
      };

      decoration = {
        rounding = 10;
        rounding_power = 2;

        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };

        blur = {
          enabled = true;
          size = 3;
          passes = 2;
          vibrancy = 0.1696;
        };
      };

      "exec-once" = [
        "noctalia"
      ];

      bind =
        (map (n: "SUPER, ${toString n}, workspace, ${toString n}") (
          [ 1 2 3 4 5 6 7 8 9 ]
        ))
        ++ [ "SUPER, 0, workspace, 10" ]
        ++ (map (n: "SUPER CTRL, ${toString n}, movetoworkspace, ${toString n}") (
          [ 1 2 3 4 5 6 7 8 9 ]
        ))
        ++ [ "SUPER CTRL, 0, movetoworkspace, 10" ]
        ++ [
          "SUPER, mouse_up, workspace, e+1"
          "SUPER, mouse_down, workspace, e-1"
          "SUPER, left, movefocus, l"
          "SUPER, right, movefocus, r"
          "SUPER, up, movefocus, u"
          "SUPER, down, movefocus, d"

          "SUPER, F, fullscreen, 0"
          "SUPER, Q, killactive"
          "SUPER, V, togglefloating"
          "SUPER, M, exec, command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"

          "SUPER, space, exec, ${ipc} panel-toggle launcher"
          "SUPER, A, exec, kitty"
          "SUPER, E, exec, thunar"
          "SUPER, W, exec, firefox"
          "SUPER, T, exec, Telegram"
          "SUPER, S, exec, steam"
          "SUPER, P, exec, ${ipc} panel-toggle session"

          "SUPER CTRL, S, exec, grim -g \"$(slurp)\" - | swappy -f -"
          "SUPER SHIFT, S, exec, grim -g \"$(slurp)\" - | wl-copy"

          "SUPER, D, exec, vesktop"
          "SUPER, D, togglespecialworkspace, communication"
          "SUPER, C, exec, spotify"
          "SUPER, C, togglespecialworkspace, music"
          "SUPER, Z, exec, qs -c noctalia-shell ipc call plugin:assistant-panel toggle"
          "SUPER, Z, exec, ${ipc} panel-toggle control-center"
        ];

      bindm = [
        "SUPER, mouse:272, movewindow"
        "SUPER, mouse:273, resizewindow"
      ];

      windowrule = [
        "match:class ^(vesktop)$, workspace 4"
        "match:class ^(Spotify)$, workspace special:music"
        "match:class ^(vesktop)$, workspace special:communication"
      ];

      layerrule = [
        "blur on, blur_popups on, ignore_alpha 1.0, match:namespace noctalia-background-.*$"
      ];

      source = [
        "~/.config/hypr/noctalia.conf"
      ];
    };
  };

  programs.kitty = {
    enable = true;
    extraConfig = ''
      include matugen-colors.conf

      font_family      JetBrains Mono Nerd Font
      font_size 11.0

      cursor_shape beam
      cursor_trail 1

      window_margin_width 21.75

      confirm_os_window_close 0

      shell fish

      map ctrl+c    copy_or_interrupt

      map ctrl+f   launch --location=hsplit --allow-remote-control kitty +kitten search.py @active-kitty-window-id
      map kitty_mod+f   launch --location=hsplit --allow-remote-control kitty +kitten search.py @active-kitty-window-id

      map page_up    scroll_page_up
      map page_down    scroll_page_down

      map ctrl+plus  change_font_size all +1
      map ctrl+equal  change_font_size all +1
      map ctrl+kp_add  change_font_size all +1
      map ctrl+minus       change_font_size all -1
      map ctrl+underscore       change_font_size all -1
      map ctrl+kp_subtract       change_font_size all -1
      map ctrl+0 change_font_size all 0
      map ctrl+kp_0 change_font_size all 0

      background_opacity 0.6
      background_blur 1

      tab_bar_edge           bottom
      tab_bar_style          powerline
      tab_powerline_style    slanted
      tab_bar_min_tabs       1
      tab_title_template     "{title}"
      active_tab_font_style   bold
      hide_window_decorations yes

      window_border_width 0

      window_margin_width 0

      # BEGIN_KITTY_THEME
      include current-theme.conf
      # END_KITTY_THEME
    '';
  };

  programs.fish = {
    enable = true;

    shellAliases = {
      ls = "eza --icons --group-directories-first -1";
    };

    shellAbbrs = {
      lg = "lazygit";
      gd = "git diff";
      ga = "git add .";
      gc = "git commit -am";
      gl = "git log";
      gs = "git status";
      gst = "git stash";
      gsp = "git stash pop";
      gp = "git push";
      gpl = "git pull";
      gsw = "git switch";
      gsm = "git switch main";
      gb = "git branch";
      gbd = "git branch -d";
      gco = "git checkout";
      gsh = "git show";

      l = "ls";
      ll = "ls -l";
      la = "ls -a";
      lla = "ls -la";
    };

    functions = {
      fish_greeting = ''
        set_color normal
        fastfetch --key-padding-left 5
      '';

      mark_prompt_start = {
        body = ''echo -en "\e]133;A\e\\"'';
        onEvent = "fish_prompt";
      };
    };

    interactiveShellInit = ''
      starship init fish | source

      command -v direnv &> /dev/null && direnv hook fish | source
      command -v zoxide &> /dev/null && zoxide init fish --cmd cd | source

      cat ~/.config/fish/conf.d/matugen-colors.fish 2> /dev/null
    '';

    shellInit = ''
      source ~/.config/fish/matugen-colors.fish
    '';
  };

  programs.fastfetch = {
    enable = true;
    settings = {
      "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";

      logo = {
        source = "/home/winarowk/Pictures/AMOGUS.PNG";
        type = "kitty";
        height = 15;
        width = 35;
        padding = {
          top = 5;
          left = 3;
        };
      };

      modules = [
        "break"
        { type = "custom"; format = "${esc}[90m┌──────────────────────Hardware──────────────────────┐"; }
        { type = "host"; key = "󰌢  PC"; keyColor = "green"; }
        { type = "cpu"; key = "│ ├󰻠 "; keyColor = "green"; }
        { type = "gpu"; key = "│ ├󰍹 "; keyColor = "green"; }
        { type = "memory"; key = "│ ├󰑭 "; keyColor = "green"; }
        { type = "disk"; key = "└ └󰋊 "; keyColor = "green"; }
        { type = "custom"; format = "${esc}[90m└────────────────────────────────────────────────────┘"; }
        "break"
        { type = "custom"; format = "${esc}[90m┌──────────────────────Software──────────────────────┐"; }
        { type = "os"; key = "  OS"; keyColor = "yellow"; }
        { type = "kernel"; key = "│ ├󰌽 "; keyColor = "yellow"; }
        { type = "bios"; key = "│ ├󰖡 "; keyColor = "yellow"; }
        { type = "packages"; key = "│ ├󰏗 "; keyColor = "yellow"; }
        { type = "shell"; key = "└ └󰞷 "; keyColor = "yellow"; }
        "break"
        { type = "de"; key = "󰧨  DE"; keyColor = "blue"; }
        { type = "lm"; key = "│ ├󰍁 "; keyColor = "blue"; }
        { type = "wm"; key = "│ ├󱂬 "; keyColor = "blue"; }
        { type = "wmtheme"; key = "│ ├󰉦 "; keyColor = "blue"; }
        { type = "terminal"; key = "└ └󰆍 "; keyColor = "blue"; }
        { type = "custom"; format = "${esc}[90m└────────────────────────────────────────────────────┘"; }
        "break"
        { type = "custom"; format = "${esc}[90m┌────────────────────Uptime / Age / DT────────────────────┐"; }
        {
          type = "command";
          key = "  ›  OS Age  ";
          keyColor = "magenta";
          text = "birth_install=$(stat -c %W /); current=$(date +%s); time_progression=$((current - birth_install)); days_difference=$((time_progression / 86400)); echo $days_difference days";
        }
        { type = "uptime"; key = "  ›  Uptime  "; keyColor = "magenta"; }
        { type = "datetime"; key = "  ›  DateTime  "; keyColor = "magenta"; }
        { type = "custom"; format = "${esc}[90m└─────────────────────────────────────────────────────────┘"; }
        { type = "colors"; paddingLeft = 2; symbol = "circle"; }
      ];
    };
  };

  xdg.configFile."matugen/config.toml".text = ''
    [config]
    image_mode = "dark"

    [templates.btop]
    input_path = "~/.config/matugen/btop-colors.theme"
    output_path = "~/.config/btop/themes/matugen.theme"

    [templates.kitty]
    input_path = "/home/winarowk/.config/matugen/kitty.conf"
    output_path = "~/.config/kitty/matugen-colors.conf"

    [templates.fish]
    input_path = "~/.config/matugen/fish-colors.fish"
    output_path = "~/.config/fish/matugen-colors.fish"
  '';

  xdg.configFile."matugen/kitty.conf".text = ''
    foreground            {{colors.on_surface.default.hex}}
    selection_foreground  {{colors.surface.default.hex}}
    selection_background  {{colors.primary.default.hex}}
    cursor                {{colors.primary.default.hex}}
    cursor_text_color     {{colors.surface.default.hex}}

    color0  {{colors.surface.default.hex}}
    color1  {{colors.error.default.hex}}
    color2  {{colors.primary.default.hex}}
    color3  {{colors.secondary.default.hex}}
    color4  {{colors.tertiary.default.hex}}
    color5  {{colors.primary.default.hex}}
    color6  {{colors.secondary.default.hex}}
    color7  {{colors.on_surface.default.hex}}

    color8  {{colors.surface_variant.default.hex}}
    color9  {{colors.error.default.hex}}
    color10 {{colors.primary.default.hex}}
    color11 {{colors.secondary.default.hex}}
    color12 {{colors.tertiary.default.hex}}
    color13 {{colors.primary.default.hex}}
    color14 {{colors.secondary.default.hex}}
    color15 {{colors.on_surface.default.hex}}
  '';

  xdg.configFile."matugen/btop-colors.theme".text = ''
    theme[main_bg]="{{colors.surface.default.hex}}"
    theme[main_fg]="{{colors.on_surface.default.hex}}"
    theme[title]="{{colors.primary.default.hex}}"
    theme[hi_fg]="{{colors.secondary.default.hex}}"
    theme[selected_bg]="{{colors.surface_variant.default.hex}}"
    theme[selected_fg]="{{colors.on_surface.default.hex}}"
    theme[inactive_fg]="{{colors.outline.default.hex}}"
    theme[graph_text]="{{colors.on_surface_variant.default.hex}}"
    theme[meter_bg]="{{colors.surface_container_highest.default.hex}}"
    theme[proc_misc]="{{colors.primary.default.hex}}"
    theme[cpu_box]="{{colors.primary.default.hex}}"
    theme[mem_box]="{{colors.secondary.default.hex}}"
    theme[net_box]="{{colors.tertiary.default.hex}}"
    theme[proc_box]="{{colors.error.default.hex}}"
    theme[div_line]="{{colors.outline_variant.default.hex}}"
    theme[temp_start]="{{colors.primary.default.hex}}"
    theme[temp_mid]="{{colors.secondary.default.hex}}"
    theme[temp_end]="{{colors.error.default.hex}}"
    theme[cpu_start]="{{colors.primary.default.hex}}"
    theme[cpu_mid]="{{colors.secondary.default.hex}}"
    theme[cpu_end]="{{colors.error.default.hex}}"
    theme[free_start]="{{colors.primary.default.hex}}"
    theme[free_mid]="{{colors.secondary.default.hex}}"
    theme[free_end]="{{colors.error.default.hex}}"
    theme[cached_start]="{{colors.tertiary.default.hex}}"
    theme[cached_mid]="{{colors.secondary.default.hex}}"
    theme[cached_end]="{{colors.primary.default.hex}}"
    theme[available_start]="{{colors.primary.default.hex}}"
    theme[available_mid]="{{colors.secondary.default.hex}}"
    theme[available_end]="{{colors.error.default.hex}}"
    theme[used_start]="{{colors.primary.default.hex}}"
    theme[used_mid]="{{colors.secondary.default.hex}}"
    theme[used_end]="{{colors.error.default.hex}}"
    theme[download_start]="{{colors.primary.default.hex}}"
    theme[download_mid]="{{colors.secondary.default.hex}}"
    theme[download_end]="{{colors.error.default.hex}}"
    theme[upload_start]="{{colors.primary.default.hex}}"
    theme[upload_mid]="{{colors.secondary.default.hex}}"
    theme[upload_end]="{{colors.error.default.hex}}"
    theme[process_start]="{{colors.primary.default.hex}}"
    theme[process_mid]="{{colors.secondary.default.hex}}"
    theme[process_end]="{{colors.error.default.hex}}"
  '';

  xdg.configFile."matugen/fish-colors.fish".text = ''
    set -U fish_color_normal {{colors.on_surface.default.hex_stripped}}
    set -U fish_color_command {{colors.tertiary.default.hex_stripped}}
    set -U fish_color_param {{colors.on_surface_variant.default.hex_stripped}}
    set -U fish_color_quote {{colors.secondary.default.hex_stripped}}
    set -U fish_color_escape {{colors.secondary.default.hex_stripped}}
    set -U fish_color_autosuggestion {{colors.outline.default.hex_stripped}}
    set -U fish_color_error {{colors.error.default.hex_stripped}}
    set -U fish_color_comment {{colors.surface_variant.default.hex_stripped}}
    set -U fish_color_selection --background={{colors.surface_container_highest.default.hex_stripped}}
    set -U fish_color_search_match --background={{colors.surface_container_highest.default.hex_stripped}}
  '';

  programs.home-manager.enable = true;
}
