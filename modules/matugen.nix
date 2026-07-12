{ config, pkgs, inputs, ... }:

{
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

    [templates.waybar]
    input_path = "~/.config/matugen/waybar-colors.css"
    output_path = "~/.config/waybar/matugen-colors.css"

    [templates.rofi]
    input_path = "~/.config/matugen/rofi-colors.rasi"
    output_path = "~/.config/rofi/matugen-colors.rasi"

    [templates.swaync]
    input_path = "~/.config/matugen/swaync-colors.css"
    output_path = "~/.config/swaync/matugen-colors.css"
    post_hook = "swaync-client --reload-css || true"

  '';

  xdg.configFile."matugen/swaync-colors.css".text = ''
    @define-color background {{colors.surface.default.hex}};
    @define-color surface {{colors.surface_container.default.hex}};
    @define-color surface_high {{colors.surface_container_highest.default.hex}};
    @define-color primary {{colors.primary.default.hex}};
    @define-color on_primary {{colors.on_primary.default.hex}};
    @define-color secondary {{colors.secondary.default.hex}};
    @define-color tertiary {{colors.tertiary.default.hex}};
    @define-color text {{colors.on_surface.default.hex}};
    @define-color text_muted {{colors.on_surface_variant.default.hex}};
    @define-color outline {{colors.outline.default.hex}};
    @define-color error {{colors.error.default.hex}};
  '';

  xdg.configFile."matugen/rofi-colors.rasi".text = ''
    * {
        background: {{colors.surface.default.hex}};
        background-trans: rgba({{colors.surface.default.red}}, {{colors.surface.default.green}}, {{colors.surface.default.blue}}, 0.8);
        surface: {{colors.surface_container.default.hex}};
        surface-high: {{colors.surface_container_highest.default.hex}};
        primary: {{colors.primary.default.hex}};
        on-primary: {{colors.on_primary.default.hex}};
        text: {{colors.on_surface.default.hex}};
        text-muted: {{colors.on_surface_variant.default.hex}};
        outline: {{colors.outline.default.hex}};
        error: {{colors.error.default.hex}};
    }
  '';

  xdg.configFile."matugen/waybar-colors.css".text = ''
    @define-color background {{colors.surface.default.hex}};
    @define-color surface {{colors.surface_container.default.hex}};
    @define-color surface_high {{colors.surface_container_highest.default.hex}};
    @define-color primary {{colors.primary.default.hex}};
    @define-color on_primary {{colors.on_primary.default.hex}};
    @define-color secondary {{colors.secondary.default.hex}};
    @define-color tertiary {{colors.tertiary.default.hex}};
    @define-color text {{colors.on_surface.default.hex}};
    @define-color text_muted {{colors.on_surface_variant.default.hex}};
    @define-color outline {{colors.outline.default.hex}};
    @define-color error {{colors.error.default.hex}};
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
}
