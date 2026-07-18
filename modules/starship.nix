{ config, pkgs, inputs, ... }:

{
  home.packages = [ pkgs.starship ];

  # Starship читает конфиг, сгенерированный matugen (цвета из обоев)
  home.sessionVariables.STARSHIP_CONFIG = "${config.xdg.configHome}/starship/starship.toml";

  # Шаблон для matugen: {{colors.*}} подставляются при смене обоев
  xdg.configFile."matugen/starship.toml".text = ''
    "$schema" = 'https://starship.rs/config-schema.json'

    add_newline = true
    palette = "matugen"

    format = """
    [](fg:primary)\
    $os\
    $username\
    [](fg:primary bg:secondary_container)\
    $directory\
    [](fg:secondary_container bg:tertiary_container)\
    $git_branch\
    $git_status\
    [](fg:tertiary_container bg:container)\
    $nix_shell\
    $nodejs\
    $python\
    $rust\
    $golang\
    $c\
    $lua\
    $java\
    [](fg:container bg:surface_variant)\
    $cmd_duration\
    $time\
    [](fg:surface_variant)\
    $line_break$character"""

    [palettes.matugen]
    primary = "{{colors.primary.default.hex}}"
    on_primary = "{{colors.on_primary.default.hex}}"
    secondary_container = "{{colors.secondary_container.default.hex}}"
    on_secondary_container = "{{colors.on_secondary_container.default.hex}}"
    tertiary_container = "{{colors.tertiary_container.default.hex}}"
    on_tertiary_container = "{{colors.on_tertiary_container.default.hex}}"
    container = "{{colors.surface_container_high.default.hex}}"
    surface_variant = "{{colors.surface_variant.default.hex}}"
    on_surface = "{{colors.on_surface.default.hex}}"
    on_surface_variant = "{{colors.on_surface_variant.default.hex}}"
    outline = "{{colors.outline.default.hex}}"
    error = "{{colors.error.default.hex}}"

    [os]
    disabled = false
    style = "bg:primary fg:on_primary"
    format = '[$symbol ]($style)'

    [os.symbols]
    NixOS = "󱄅"
    Arch = "󰣇"
    Ubuntu = "󰕈"
    Debian = "󰣚"
    Fedora = "󰣛"
    Linux = "󰌽"
    Macos = "󰀵"
    Windows = "󰍲"

    [username]
    show_always = false
    style_user = "bg:primary fg:on_primary"
    style_root = "bg:primary fg:on_primary bold"
    format = '[$user ]($style)'

    [directory]
    style = "bg:secondary_container fg:on_secondary_container"
    read_only_style = "bg:secondary_container fg:on_secondary_container"
    format = '[ $path ]($style)[$read_only ]($read_only_style)'
    truncation_length = 3
    truncation_symbol = "…/"
    read_only = "󰌾"

    [directory.substitutions]
    "Documents" = "󰈙 "
    "Downloads" = " "
    "Music" = "󰝚 "
    "Pictures" = " "
    "Videos" = " "
    "Developer" = "󰲋 "

    [git_branch]
    symbol = ""
    style = "bg:tertiary_container fg:on_tertiary_container"
    format = '[ $symbol $branch ]($style)'

    [git_status]
    style = "bg:tertiary_container fg:on_tertiary_container"
    format = '[($all_status$ahead_behind )]($style)'

    [nix_shell]
    symbol = "󱄅"
    style = "bg:container fg:on_surface"
    format = '[ $symbol $state ]($style)'

    [nodejs]
    symbol = ""
    style = "bg:container fg:on_surface"
    format = '[ $symbol( $version) ]($style)'

    [python]
    symbol = ""
    style = "bg:container fg:on_surface"
    format = '[ $symbol( $version)( $virtualenv) ]($style)'

    [rust]
    symbol = "󱘗"
    style = "bg:container fg:on_surface"
    format = '[ $symbol( $version) ]($style)'

    [golang]
    symbol = ""
    style = "bg:container fg:on_surface"
    format = '[ $symbol( $version) ]($style)'

    [c]
    symbol = ""
    style = "bg:container fg:on_surface"
    format = '[ $symbol( $version) ]($style)'

    [lua]
    symbol = ""
    style = "bg:container fg:on_surface"
    format = '[ $symbol( $version) ]($style)'

    [java]
    symbol = ""
    style = "bg:container fg:on_surface"
    format = '[ $symbol( $version) ]($style)'

    [cmd_duration]
    min_time = 1500
    style = "bg:surface_variant fg:on_surface_variant"
    format = '[ 󱎫 $duration ]($style)'

    [time]
    disabled = false
    time_format = "%H:%M"
    style = "bg:surface_variant fg:on_surface_variant"
    format = '[  $time ]($style)'

    [character]
    success_symbol = '[❯](bold fg:primary)'
    error_symbol = '[❯](bold fg:error)'
    vimcmd_symbol = '[❮](bold fg:primary)'

    [line_break]
    disabled = false
  '';
}
