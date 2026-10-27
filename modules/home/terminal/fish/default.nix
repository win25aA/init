# fish: основа (приветствие, промпт, инициализация).
{ ... }:

{
  imports = [
    ./abbreviations.nix # Сокращения команд Fish
    ./nixos-helpers.nix # Команды nrs и nback: пересборка и откат
  ];

  programs.fish = {
    enable = true;

    shellAliases = {
      ls = "eza --icons --group-directories-first -1";
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
    '';

    shellInit = ''
      test -f ~/.config/fish/matugen-colors.fish; and source ~/.config/fish/matugen-colors.fish
    '';
  };
}
