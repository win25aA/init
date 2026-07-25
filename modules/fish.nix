{ config, pkgs, inputs, ... }:

{
  programs.fish = {
    enable = true;

    # ===== Алиасы =====
    shellAliases = {
      ls = "eza --icons --group-directories-first -1";
    };

    # ===== Аббы =====
    shellAbbrs = {
      # --- git ---
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

      # --- ls ---
      l = "ls";
      ll = "ls -l";
      la = "ls -a";
      lla = "ls -la";
    };

    # ===== Функ =====
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
            echo "конфиг собрался, гит пуш."
            set_color normal

            cd $config_dir
            git add -A
            if git diff --cached --quiet
                echo "Изменений нет."
            else
                git commit -m "auto: successful rebuild "(date "+%Y-%m-%d %H:%M")
                # force-with-lease нужен, чтобы пуш работал после nback
                # (безопасный вариант force: не затрёт чужие коммиты)
                git push --force-with-lease
            end
        else
            set_color red
            echo "хуйня конфиг переделывай."
            set_color normal
        end
      '';

      # nback: откатить конфиг к последней УСПЕШНОЙ сборке.
      # Как откат через GRUB, только для текста конфига: nrs коммитит
      # только собравшийся конфиг, так что коммиты "auto: successful
      # rebuild" - гарантированно рабочие точки.
      nback = ''
        set -l config_dir /etc/nixos
        cd $config_dir

        set -l good (git log --grep="auto: successful rebuild" -n 1 --format=%H)
        if test -z "$good"
            set_color red
            echo "Не нашла коммит успешной сборки в истории."
            set_color normal
            return 1
        end

        # Незакоммиченные правки не удаляем, а прячем в stash
        if not git diff --quiet; or not git diff --cached --quiet; or test (git ls-files --others --exclude-standard | count) -gt 0
            git stash push --include-untracked -m "nback: правки перед откатом"
            echo "Твои незакоммиченные правки спрятаны в stash (вернуть: git stash pop)"
        end

        git reset --hard $good
        set_color green
        echo "Конфиг откачен к последней успешной сборке:"
        set_color normal
        git log -1 --oneline
        echo "Теперь пересборка: nrs"
      '';
    };

    # ===== Инит шелла =====
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
