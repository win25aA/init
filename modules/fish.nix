{ config, pkgs, inputs, ... }:

{
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

      nrs = ''
        set -l config_dir /etc/nixos

        sudo nixos-rebuild switch --flake $config_dir#winarowk

        if test $status -eq 0
            echo ""
            set_color green
            echo "Сборка прошла успешно, пушу конфиг в GitHub..."
            set_color normal

            cd $config_dir
            git add -A
            if git diff --cached --quiet
                echo "Изменений нет, пушить нечего."
            else
                git commit -m "auto: successful rebuild "(date "+%Y-%m-%d %H:%M")
                git push
            end
        else
            set_color red
            echo "Сборка упала — пуш отменён, чинить конфиг."
            set_color normal
        end
      '';
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
