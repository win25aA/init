{ config, pkgs, inputs, ... }:

{
  home.packages = [ pkgs.starship ];

  # Starship читает конфиг, сгенерированный matugen (цвета из обоев)
  home.sessionVariables.STARSHIP_CONFIG = "${config.xdg.configHome}/starship/starship.toml";

  # Шаблон для matugen: {{colors.*}} подставляются при смене обоев.
  # Стиль: минимализм без фоновых блоков — только цветной текст и иконки.
  xdg.configFile."matugen/starship.toml".text = ''
    "$schema" = 'https://starship.rs/config-schema.json'

    add_newline = true
    palette = "matugen"

    format = """
    [╭─](fg:outline) $os$directory$git_branch$git_status$nix_shell$nodejs$python$rust$golang$c$lua$java$cmd_duration
    [╰─](fg:outline)$character"""

    [palettes.matugen]
    primary = "{{colors.primary.default.hex}}"
    secondary = "{{colors.secondary.default.hex}}"
    tertiary = "{{colors.tertiary.default.hex}}"
    error = "{{colors.error.default.hex}}"
    outline = "{{colors.outline.default.hex}}"
    on_surface_variant = "{{colors.on_surface_variant.default.hex}}"

    [os]
    disabled = false
    style = "bold fg:primary"
    format = '[$symbol]($style) '

    [os.symbols]
    NixOS = "󱄅"
    Arch = "󰣇"
    Ubuntu = "󰕈"
    Debian = "󰣚"
    Fedora = "󰣛"
    Linux = "󰌽"
    Macos = "󰀵"
    Windows = "󰍲"

    [directory]
    style = "bold fg:primary"
    read_only_style = "fg:error"
    format = '[$path]($style)[ $read_only]($read_only_style)  '
    truncation_length = 4
    truncate_to_repo = true
    truncation_symbol = "…/"
    read_only = "󰌾"

    [git_branch]
    symbol = ""
    style = "bold fg:tertiary"
    format = '[$symbol $branch]($style) '

    [git_status]
    style = "fg:error"
    format = '([$all_status$ahead_behind]($style) )'
    conflicted = "󰞇 "
    ahead = "⇡''${count} "
    behind = "⇣''${count} "
    diverged = "⇡''${ahead_count}⇣''${behind_count} "
    untracked = "?''${count} "
    stashed = "󰏗 "
    modified = "!''${count} "
    staged = "+''${count} "
    renamed = "»''${count} "
    deleted = "✘''${count} "

    [nix_shell]
    symbol = "󱄅"
    style = "fg:secondary"
    format = '[$symbol $state]($style) '

    [nodejs]
    symbol = ""
    style = "fg:secondary"
    format = '[$symbol( $version)]($style) '

    [python]
    symbol = ""
    style = "fg:secondary"
    format = '[$symbol( $version)( $virtualenv)]($style) '

    [rust]
    symbol = "󱘗"
    style = "fg:secondary"
    format = '[$symbol( $version)]($style) '

    [golang]
    symbol = ""
    style = "fg:secondary"
    format = '[$symbol( $version)]($style) '

    [c]
    symbol = ""
    style = "fg:secondary"
    format = '[$symbol( $version)]($style) '

    [lua]
    symbol = ""
    style = "fg:secondary"
    format = '[$symbol( $version)]($style) '

    [java]
    symbol = ""
    style = "fg:secondary"
    format = '[$symbol( $version)]($style) '

    [cmd_duration]
    min_time = 2000
    style = "fg:on_surface_variant"
    format = '[󱎫 $duration]($style) '

    [character]
    success_symbol = '[❯](bold fg:primary)'
    error_symbol = '[❯](bold fg:error)'
    vimcmd_symbol = '[❮](bold fg:tertiary)'
  '';
}
