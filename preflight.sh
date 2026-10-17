#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
missing=0
for file in hardware-configuration.nix simple-sddm-2 grub-theme; do
  if [[ ! -e "$root/$file" ]]; then
    printf 'Нужен исходный файл/каталог: %s/%s\n' "$root" "$file"
    missing=1
  fi
done
if [[ ! -d "$root/wallpapers" ]]; then
  printf 'Предупреждение: wallpapers/ отсутствует; будет использована резервная палитра.\n'
fi
if (( missing )); then
  printf 'Скопируй комплект поверх существующего репозитория, сохранив указанные файлы.\n'
  exit 1
fi
command -v nix >/dev/null || { echo 'Нужен Nix с поддержкой flakes.'; exit 1; }
printf 'Проверка конфигурации, без установки и без обновления lock-файла…\n'
nix eval --no-write-lock-file --raw "path:$root#nixosConfigurations.winarowk.config.system.build.toplevel.drvPath"
printf '\nОценка завершена. Теперь можно выполнить nixos-rebuild build.\n'
