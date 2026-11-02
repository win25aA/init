# Терминал: kitty, fastfetch, btop.
{ config, lib, pkgs, inputs, ... }:

lib.mkMerge [
  # ════════════════════════════════════════════════════════════
  # kitty: терминал.
  {
    programs.kitty = {
      enable = true;
      extraConfig = ''
        include matugen-colors.conf

        font_family      JetBrains Mono Nerd Font
        font_size 11.0

        cursor_shape beam
        cursor_trail 1
        remember_window_size no
        confirm_os_window_close 0
        hide_window_decorations yes
        window_border_width 0
        window_margin_width 0
        background_opacity 0.6
        background_blur 1

        shell fish

        map ctrl+c    copy_or_interrupt
        map ctrl+v    paste_from_clipboard

        map ctrl+f   launch --location=hsplit --allow-remote-control kitty +kitten search.py @active-kitty-window-id
        map kitty_mod+f   launch --location=hsplit --allow-remote-control kitty +kitten search.py @active-kitty-window-id

        map page_up    scroll_page_up
        map page_down    scroll_page_down

        tab_bar_edge           bottom
        tab_bar_style          powerline
        tab_powerline_style    slanted
        tab_bar_min_tabs       1
        tab_title_template     "{title}"
        active_tab_font_style   bold

        # BEGIN_KITTY_THEME
        include current-theme.conf
        # END_KITTY_THEME
      '';
    };
  }

  # ════════════════════════════════════════════════════════════
  # fastfetch: информация о системе при запуске fish.
  (
    let
      esc = builtins.fromJSON ''"\u001b"'';

      logoFile = builtins.path {
        path = ../wallpapers/.face;
        name = "fastfetch-logo.png";
      };
    in
    {
      programs.fastfetch = {
        enable = true;
        settings = {
          "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";


          logo = {
            source = "${logoFile}";
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
    }
  )

  # ════════════════════════════════════════════════════════════
  # btop: монитор ресурсов (с поддержкой CUDA/NVIDIA).
  {
    programs.btop = {
      enable = true;
      package = pkgs.btop.override { cudaSupport = true; };
      settings = {

        color_theme = "matugen";
        theme_background = false;
        truecolor = true;
        force_tty = false;
        rounded_corners = true;
        terminal_sync = true;
        vim_keys = false;
        disable_mouse = false;


        shown_boxes = "cpu mem net proc gpu0";
        disable_presets = "Off";
        presets = "cpu:1:default,proc:0:default cpu:0:default,mem:0:default,net:0:default cpu:0:block,net:0:tty";
        update_ms = 1000;


        graph_symbol = "braille";
        graph_symbol_cpu = "default";
        graph_symbol_gpu = "default";
        graph_symbol_mem = "default";
        graph_symbol_net = "default";
        graph_symbol_proc = "default";

        # ===== Процессы =====
        proc_sorting = "memory";
        proc_reversed = false;
        proc_tree = false;
        proc_colors = true;
        proc_gradient = true;
        proc_per_core = false;
        proc_mem_bytes = true;
        proc_cpu_graphs = true;
        proc_info_smaps = false;
        proc_left = false;
        proc_filter_kernel = false;
        proc_follow_detailed = true;
        proc_aggregate = false;
        keep_dead_proc_usage = false;


        cpu_graph_upper = "Auto";
        cpu_graph_lower = "Auto";
        cpu_invert_lower = true;
        cpu_single_graph = false;
        cpu_bottom = false;
        show_uptime = true;
        show_cpu_watts = true;
        check_temp = true;
        cpu_sensor = "Auto";
        show_coretemp = true;
        cpu_core_map = "";
        temp_scale = "celsius";
        show_cpu_freq = true;
        freq_mode = "first";
        custom_cpu_name = "";


        mem_graphs = true;
        mem_below_net = false;
        zfs_arc_cached = true;
        show_swap = true;
        swap_disk = true;
        show_disks = true;
        only_physical = true;
        use_fstab = true;
        zfs_hide_datasets = false;
        disk_free_priv = false;
        show_io_stat = true;
        io_mode = false;
        io_graph_combined = false;
        io_graph_speeds = "";
        disks_filter = "";
        base_10_sizes = false;


        swap_upload_download = false;
        net_download = 100;
        net_upload = 100;
        net_auto = true;
        net_sync = true;
        net_iface = "";
        base_10_bitrate = "Auto";


        show_battery = true;
        selected_battery = "Auto";
        show_battery_watts = true;


        show_gpu_info = "Auto";
        nvml_measure_pcie_speeds = true;
        rsmi_measure_pcie_speeds = true;
        gpu_mirror_graph = true;
        shown_gpus = "nvidia amd intel";
        custom_gpu_name0 = "";
        custom_gpu_name1 = "";
        custom_gpu_name2 = "";
        custom_gpu_name3 = "";
        custom_gpu_name4 = "";
        custom_gpu_name5 = "";


        clock_format = "%X";
        background_update = true;
        log_level = "WARNING";
        save_config_on_exit = true;
      };
    };
  }
]
