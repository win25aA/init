# Fish: оболочка и команды nrs / nback.
{ lib, ... }:

lib.mkMerge [
  # ════════════════════════════════════════════════════════════
  # Fish: сокращения, приветствие, промпт и инициализация.
  # Пересборка и откат системы — ниже, в следующем блоке.
  {
    programs.fish = {
      enable = true;

      # Сокращения команд
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

  # ════════════════════════════════════════════════════════════
  # fish: команды для работы с этим конфигом.
  #   nrs   — пересобрать систему и запушить конфиг
  #   nf    — найти, где в конфиге написано слово (nf HDMI)
  #   nback — откатить конфиг к прошлой успешной сборке (nback | nback 3 | nback list)
  {
    programs.fish.functions = {
      nrs = ''
        set -l config_dir /etc/nixos

        sudo nixos-rebuild switch --flake $config_dir#(hostname)

        if test $status -eq 0
            echo ""
            set_color green
            echo "конфиг собрался, гит пуш."
            set_color normal

            cd $config_dir
            git add -A
            # Метка нужна nback: он откатывает к последнему "auto: successful rebuild"
            if git diff --cached --quiet
                if git log -1 --format=%s | string match -q "auto: successful rebuild*"
                    echo "Изменений нет, метка уже стоит."
                else
                    git commit --allow-empty -m "auto: successful rebuild "(date "+%Y-%m-%d %H:%M")
                    git push --force-with-lease
                end
            else
                git commit -m "auto: successful rebuild "(date "+%Y-%m-%d %H:%M")
                git push --force-with-lease
            end
        else
            set_color red
            echo "хуйня конфиг переделывай."
            set_color normal
        end
      '';

      # nback: откат конфига к успешной сборке
      # nback | nback 3 | nback list
      # nf: найти, в каком файле конфига что-то написано
      # nf монитор | nf HDMI | nf kitty
      nf = ''
        if test (count $argv) -eq 0
            echo "Что искать? Пример: nf HDMI"
            return 1
        end
        grep -rn -i --color=always --exclude-dir=.git -- "$argv" /etc/nixos
      '';

      nback = ''
        set -l config_dir /etc/nixos
        cd $config_dir

        set -l n 1
        if test (count $argv) -ge 1
            if test "$argv[1]" = list
                echo "Последние успешные сборки (nback 1 - верхняя):"
                git log --grep="auto: successful rebuild" -n 15 \
                    --format="%h  %ad" --date=format:"%d.%m.%Y %H:%M" | cat -n
                return 0
            end
            set n $argv[1]
        end

        set -l good (git log --grep="auto: successful rebuild" -n $n --format=%H | tail -n 1)
        if test -z "$good"
            set_color red
            echo "Не нашла столько успешных сборок в истории."
            set_color normal
            return 1
        end

        echo "Цель отката:"
        git log -1 --format="  %h  %ad  %s" --date=format:"%d.%m.%Y %H:%M" $good
        read -P "Откатываем? [y/N] " ans
        if test "$ans" != y; and test "$ans" != Y
            echo "Отменено."
            return 1
        end

        if not git diff --quiet; or not git diff --cached --quiet; or test (git ls-files --others --exclude-standard | count) -gt 0
            git stash push --include-untracked -m "nback: правки перед откатом"
            echo "Твои незакоммиченные правки спрятаны в stash (вернуть: git stash pop)"
        end

        git reset --hard $good
        set_color green
        echo "Конфиг откачен. Теперь пересборка: nrs"
        set_color normal
      '';
    };
  }
]
