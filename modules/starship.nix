{ config, pkgs, inputs, ... }:

{
  home.packages = [ pkgs.starship ];

  # Starship читает конфиг, сгенерированный matugen (цвета из обоев)
  home.sessionVariables.STARSHIP_CONFIG = "${config.xdg.configHome}/starship/starship.toml";

  # Шаблон для matugen: {{colors.*}} подставляются при смене обоев.
  # Стиль: отдельные закруглённые "пилюли" (капсулы) с воздухом между ними.
  xdg.configFile."matugen/starship.toml".text = ''
    "$schema" = 'https://starship.rs/config-schema.json'

    add_newline = true
    palette = "matugen"

    format = """
    $os$directory$git_branch$git_status$nix_shell$nodejs$python$rust$golang$c$lua$java$cmd_duration
    $character"""

    right_format = """$time"""

    [palettes.matugen]
    primary = "{{colors.primary.default.hex}}"
    on_primary = "{{colors.on_primary.default.hex}}"
    sec_c = "{{colors.secondary_container.default.hex}}"
    on_sec_c = "{{colors.on_secondary_container.default.hex}}"
    ter_c = "{{colors.tertiary_container.default.hex}}"
    on_ter_c = "{{colors.on_tertiary_container.default.hex}}"
    container = "{{colors.surface_container_high.default.hex}}"
    on_surface = "{{colors.on_surface.default.hex}}"
    surf_var = "{{colors.surface_variant.default.hex}}"
    on_surf_var = "{{colors.on_surface_variant.default.hex}}"
    tertiary = "{{colors.tertiary.default.hex}}"
    error = "{{colors.error.default.hex}}"

    # ── пилюля: NixOS ──────────────────────────────────────────────
    [os]
    disabled = false
    format = '[](fg:primary)[$symbol](bg:primary fg:on_primary)[](fg:primary) '

    [os.symbols]
    NixOS = "󱄅 "
    Arch = "󰣇 "
    Ubuntu = "󰕈 "
    Debian = "󰣚 "
    Fedora = "󰣛 "
    Linux = "󰌽 "
    Macos = "󰀵 "
    Windows = "󰍲 "

    # ── пилюля: директория ─────────────────────────────────────────
    [directory]
    format = '[](fg:sec_c)[󰉋 $path](bg:sec_c fg:on_sec_c)[$read_only](bg:sec_c fg:error)[](fg:sec_c) '
    truncation_length = 4
    truncate_to_repo = true
    truncation_symbol = "…/"
    read_only = " 󰌾"

    [directory.substitutions]
    "Documents" = "󰈙"
    "Downloads" = ""
    "Music" = "󰝚"
    "Pictures" = ""
    "Videos" = ""

    # ── пилюля: git (ветка + статус в одной капсуле) ───────────────
    [git_branch]
    symbol = ""
    format = '[](fg:ter_c)[$symbol $branch](bg:ter_c fg:on_ter_c)'

    [git_status]
    style = "bg:ter_c fg:on_ter_c"
    format = '([ $all_status$ahead_behind]($style))[](fg:ter_c) '
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

    # ── пилюли: окружение / языки ──────────────────────────────────
    [nix_shell]
    symbol = "󱄅"
    format = '[](fg:container)[$symbol $state](bg:container fg:on_surface)[](fg:container) '

    [nodejs]
    symbol = ""
    format = '[](fg:container)[$symbol( $version)](bg:container fg:on_surface)[](fg:container) '

    [python]
    symbol = ""
    format = '[](fg:container)[$symbol( $version)( $virtualenv)](bg:container fg:on_surface)[](fg:container) '

    [rust]
    symbol = "󱘗"
    format = '[](fg:container)[$symbol( $version)](bg:container fg:on_surface)[](fg:container) '

    [golang]
    symbol = ""
    format = '[](fg:container)[$symbol( $version)](bg:container fg:on_surface)[](fg:container) '

    [c]
    symbol = ""
    format = '[](fg:container)[$symbol( $version)](bg:container fg:on_surface)[](fg:container) '

    [lua]
    symbol = ""
    format = '[](fg:container)[$symbol( $version)](bg:container fg:on_surface)[](fg:container) '

    [java]
    symbol = ""
    format = '[](fg:container)[$symbol( $version)](bg:container fg:on_surface)[](fg:container) '

    # ── пилюля: время выполнения ───────────────────────────────────
    [cmd_duration]
    min_time = 2000
    format = '[](fg:surf_var)[󱎫 $duration](bg:surf_var fg:on_surf_var)[](fg:surf_var) '

    # ── пилюля справа: часы ────────────────────────────────────────
    [time]
    disabled = false
    time_format = "%H:%M"
    format = '[](fg:surf_var)[ $time](bg:surf_var fg:on_surf_var)[](fg:surf_var)'

    [character]
    success_symbol = '[❯](bold fg:primary)'
    error_symbol = '[❯](bold fg:error)'
    vimcmd_symbol = '[❮](bold fg:tertiary)'
  '';
}
