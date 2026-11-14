# Fish: оболочка, команды nrs / nback, PATH и npm.
{ lib, ... }:

lib.mkMerge [
  # Настройки fish
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
          fastfetch
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

  # Команды для конфига
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
            echo "Система пересобрана. Проверь файлы перед отправкой на GitHub:"
            set_color normal

            cd $config_dir; or return 1
            git status --short --untracked-files=all; or return 1
            echo "Будут добавлены все изменения, включая новые файлы. Проверь, нет ли среди них паролей и личных данных."
            read -P "Закоммитить и отправить? [y/N] " ans
            if test "$ans" != y; and test "$ans" != Y
                echo "Git не изменён и отправки не было. Система уже пересобрана."
                return 0
            end
            git add -A; or return 1
            # Метка нужна nback. Если коммит не удался, ничего не отправляем.
            if git diff --cached --quiet
                if git log -1 --format=%s | string match -q "auto: successful rebuild*"
                    echo "Изменений нет, метка уже стоит."
                else
                    git commit --allow-empty -m "auto: successful rebuild "(date "+%Y-%m-%d %H:%M"); or return 1
                end
            else
                git commit -m "auto: successful rebuild "(date "+%Y-%m-%d %H:%M"); or return 1
            end
            set -l branch (git symbolic-ref --quiet --short HEAD)
            if test -z "$branch"
                echo "Нет активной ветки. Коммит сохранён локально, push не выполнен."
                return 1
            end
            set -l remote (git config --get "branch.$branch.remote")
            set -l target (git config --get "branch.$branch.merge")
            if test -z "$remote"; or test -z "$target"; or not string match -q 'refs/heads/*' -- "$target"
                echo "У ветки нет настроенной удалённой ветки. Коммит сохранён локально, push не выполнен."
                return 1
            end
            if git push --no-force "$remote" "HEAD:$target"
                echo "Отправлено."
            else
                echo "Push не прошёл. Коммит сохранён локально; проверь изменения на GitHub. Принудительной отправки не было."
                return 1
            end
        else
            set_color red
            echo "хуйня конфиг переделывай."
            set_color normal
        end
      '';

      # Диагностика после первой загрузки: только просмотр, ничего не меняет.
      ncheck = ''
        echo "=== Система ==="
        uname -a
        echo "=== Диски и монтирования ==="
        lsblk -f
        echo "=== Неудавшиеся службы ==="
        systemctl --failed --no-pager
        echo "=== Сеть ==="
        if command -q nmcli
            nmcli general status
        end
        echo "=== Звук ==="
        if command -q wpctl
            wpctl status
        else
            echo "wpctl недоступен в этой сессии."
        end
        if command -q nvidia-smi
            echo "=== NVIDIA ==="
            nvidia-smi
        end
        if set -q HYPRLAND_INSTANCE_SIGNATURE; and command -q hyprctl
            echo "=== Мониторы Hyprland ==="
            hyprctl monitors
        else if set -q SWAYSOCK; and command -q swaymsg
            echo "=== Мониторы Sway ==="
            swaymsg -t get_outputs
        else if set -q DISPLAY; and command -q xrandr
            echo "=== Мониторы X11 ==="
            xrandr --query
        end
        echo "Проверь также изображение, звук и соединение вручную."
      '';

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

  # PATH и npm
  {
    home.sessionVariables = {
      NPM_CONFIG_PREFIX = "$HOME/.npm-global";
    };

    home.sessionPath = [
      "$HOME/.npm-global/bin"
      "$HOME/.local/bin"
    ];
  }
]
