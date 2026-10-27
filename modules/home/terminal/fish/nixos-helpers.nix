# fish: команды для работы с этим конфигом.
#   nrs   — пересобрать систему и запушить конфиг
#   nback — откатить конфиг к прошлой успешной сборке (nback | nback 3 | nback list)
{ ... }:

{
  programs.fish.functions = {
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
