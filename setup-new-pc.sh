#!/usr/bin/env bash
# Подготовка общего конфига для уже установленной NixOS. Диски не форматирует.
set -Eeuo pipefail

say() { printf '%s\n' "$*"; }
die() { printf '\nОшибка: %s\n' "$*" >&2; exit 1; }
confirm() {
  local answer
  read -r -p "$1 [y/N] " answer
  [[ "$answer" == y || "$answer" == Y ]]
}

[[ $EUID -ne 0 ]] || die 'Запусти без sudo: bash setup-new-pc.sh. Sudo будет запрошен, когда понадобится.'
[[ -r /etc/os-release ]] || die 'Не найдена информация о системе.'
# shellcheck disable=SC1091
. /etc/os-release
[[ "${ID:-}" == nixos ]] || die 'Скрипт рассчитан на уже установленную NixOS.'
for cmd in git nix sudo nixos-generate-config nixos-rebuild lsblk findmnt realpath; do
  command -v "$cmd" >/dev/null || die "Не найдена команда $cmd. Если нет Git: nix-shell -p git"
done
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo=$(git -C "$script_dir" rev-parse --show-toplevel 2>/dev/null) || die 'Запусти скрипт из клонированного Git-репозитория.'
repo=$(realpath "$repo")
[[ -d "$repo/.git" && ! -L "$repo/.git" ]] || die 'Нужна обычная копия репозитория, а не Git worktree или симлинк .git.'
[[ "$repo" != *$'\n'* ]] || die 'Путь к конфигу не должен содержать перевод строки.'
case "$repo/" in /etc/nixos/*) [[ "$repo" == /etc/nixos ]] || die 'Копия лежит внутри /etc/nixos. Перемести её за пределы этой папки и попробуй снова.';; esac

say 'Этот скрипт для уже установленной NixOS. Он не форматирует диски и не делает git push.'
say 'Он создаст новый host, проверит сборку и только с твоего подтверждения применит конфиг.'
say 'Общие программы и настройки берутся из этого репозитория; существующий конфиг будет сохранён.'
say 'Важно: при применении системные службы и настройки заменятся настройками этого конфига.'
say 'Создай резервную копию важных данных перед применением. На новом ПК нужен доступ к интернету.'
say

current_hostname=$(hostname -s 2>/dev/null || true)
if [[ ! "$current_hostname" =~ ^[a-z][a-z0-9-]{0,62}$ || "$current_hostname" == *- ]]; then current_hostname=pc; fi
read -r -p "Имя нового ПК [$current_hostname]: " host
host=${host:-$current_hostname}
[[ "$host" =~ ^[a-z][a-z0-9-]{0,62}$ && "$host" != *- ]] || die 'Имя: строчные латинские буквы, цифры и дефис; начать с буквы, не заканчивать дефисом.'
hostdir="$repo/hosts/$host"
[[ ! -e "$hostdir" && ! -L "$hostdir" ]] || die "Папка hosts/$host уже есть. Она не будет перезаписана; выбери другое имя."

# Определяем только типы PCI-видеокарт. Гибридные и неопределённые варианты не угадываем.
declare -A vendors=()
for dev in /sys/bus/pci/devices/*; do
  [[ -r "$dev/class" && -r "$dev/vendor" ]] || continue
  read -r class < "$dev/class" || continue
  [[ "$class" == 0x03* ]] || continue
  read -r vendor < "$dev/vendor" || continue
  case "$vendor" in 0x10de) vendors[nvidia]=1;; 0x1002) vendors[amd]=1;; 0x8086) vendors[intel]=1;; esac
done
if (( ${#vendors[@]} == 1 )); then
  for gpu in "${!vendors[@]}"; do :; done
elif (( ${#vendors[@]} == 0 )); then
  gpu=other
else
  say 'Найдено несколько типов видеокарт; автоматически выбрать драйвер нельзя.'
  printf 'Обнаружено:'; printf ' %s' "${!vendors[@]}"; printf '\n'
  read -r -p 'Укажи основной тип (nvidia / amd / intel / other): ' gpu
fi
case "$gpu" in nvidia|amd|intel|other) ;; *) die 'Неизвестный тип видеокарты.';; esac
if [[ "$gpu" == nvidia ]]; then
  say 'В общем конфиге для NVIDIA выбран драйвер legacy 580; он подходит не всем картам.'
  say 'Для гибридной графики может понадобиться отдельная настройка.'
  confirm 'Ты проверила, что legacy 580 подходит этой видеокарте?' || die 'Драйвер не подтверждён; настройки не созданы.'
fi

if [[ -d /sys/firmware/efi ]]; then
  mode=uefi
  grub_device=nodev
else
  mode=bios
  say 'Обнаружен BIOS. Загрузчик GRUB устанавливается на целый диск, не на раздел.'
  lsblk -d -o NAME,SIZE,MODEL,TYPE
  read -r -p 'Укажи диск загрузчика, например /dev/sda (или /dev/disk/by-id/...): ' grub_device
  [[ "$grub_device" =~ ^/dev/[a-zA-Z0-9_./-]+$ && -b "$grub_device" ]] || die 'Не найдено указанное блочное устройство.'
  [[ "$(lsblk -dn -o TYPE -- "$grub_device" | tr -d '[:space:]')" == disk ]] || die 'Нужен целый диск, а не раздел.'
  say "Выбран диск: $grub_device. При применении GRUB будет записан на него."
  confirm 'Это правильный диск для загрузчика?' || die 'Диск не подтверждён; настройки не созданы.'
fi

# stateVersion не равна текущей версии NixOS. Используем только явно найденное значение.
state_version=''
if [[ -r /etc/nixos/configuration.nix ]]; then
  mapfile -t versions < <(sed -nE 's/^[[:space:]]*system\.stateVersion[[:space:]]*=[[:space:]]*"([0-9]{2}\.[0-9]{2})".*/\1/p' /etc/nixos/configuration.nix)
  if (( ${#versions[@]} == 1 )); then state_version=${versions[0]}; fi
fi
if [[ -n "$state_version" ]]; then
  read -r -p "system.stateVersion на этом ПК [$state_version]: " entered_version
  state_version=${entered_version:-$state_version}
else
  say 'Не удалось однозначно прочитать system.stateVersion из /etc/nixos/configuration.nix.'
  say 'Укажи прежнее значение этого ПК, например 25.11. Это не обязательно текущая версия NixOS.'
  read -r -p 'system.stateVersion: ' state_version
fi
[[ "$state_version" =~ ^[0-9]{2}\.[0-9]{2}$ ]] || die 'Неверный формат system.stateVersion.'

say
say "Будет создан hosts/$host: GPU=$gpu, загрузка=$mode, GRUB=$grub_device, stateVersion=$state_version."
say 'Пользователь нового конфига: winarowk. Общий список программ не меняется.'
confirm 'Создать host и проверить сборку?' || die 'Отменено; настройки не созданы.'

mkdir -- "$hostdir"
if ! sudo nixos-generate-config --show-hardware-config > "$hostdir/hardware-configuration.nix"; then
  die "Не удалось получить конфигурацию железа. Папка hosts/$host оставлена для проверки; существующие файлы не менялись."
fi
cat > "$hostdir/default.nix" <<NIX
# Создано setup-new-pc.sh для этого компьютера.
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../system
  ];

  my.gpu = "$gpu";
  my.boot = {
    mode = "$mode";
    grubDevice = "$grub_device";
  };

  # Hyprland и Sway включают мониторы без привязки к старому ПК.
  system.stateVersion = "$state_version";
}
NIX

say
say 'Обнаруженные настройки файловых систем и дисков:'
grep -A 5 -E 'fileSystems\.|swapDevices' "$hostdir/hardware-configuration.nix" || true
say 'Проверь, нет ли здесь лишних временных или съёмных дисков.'
confirm 'Продолжить сборку?' || die "Остановлено. Папка hosts/$host сохранена для проверки."
# Flake в Git не видит неотслеживаемые файлы. Staging не создаёт коммит и не пушит.
git -C "$repo" add -- "hosts/$host/default.nix" "hosts/$host/hardware-configuration.nix"
say 'Проверяю сборку; это может занять время. Система пока не переключается.'
nix --extra-experimental-features 'nix-command flakes' build --no-link "$repo#nixosConfigurations.$host.config.system.build.toplevel" || die "Сборка не прошла. Host оставлен в hosts/$host, существующая система не переключалась."

say
say 'Сборка прошла. Применение заменит текущие системные настройки настройками этого конфига.'
say 'Приложения, домашние файлы, пароли и настройки вне конфига автоматически не переносятся.'
say 'Убедись, что есть резервная копия и способ вернуться к предыдущей загрузке NixOS.'
if [[ "$mode" == bios ]]; then
  say "GRUB будет установлен на $grub_device."
else
  if ! findmnt -n --mountpoint /boot >/dev/null; then
    die 'UEFI: /boot не является отдельной смонтированной файловой системой. Проверь расположение EFI-раздела и настройку загрузчика перед применением.'
  fi
  esp_type=$(findmnt -n -o FSTYPE --mountpoint /boot)
  [[ "$esp_type" == vfat ]] || die "UEFI: /boot имеет тип $esp_type, а не vfat. Проверь EFI-раздел перед применением."
fi

if [[ "$repo" != /etc/nixos ]]; then
  [[ ! -L /etc/nixos ]] || die '/etc/nixos — симлинк. Автоматически заменять его скрипт не будет.'
  [[ ! -e /etc/nixos/.git ]] || die '/etc/nixos уже содержит Git-репозиторий. Автоматически заменять его скрипт не будет.'
  say "Текущий /etc/nixos будет переименован в резервную копию, а $repo будет скопирован в /etc/nixos."
  say 'Это нужно, потому что Noctalia, обои и nrs пока используют /etc/nixos.'
fi
if [[ $(id -un) != winarowk ]] && ! id -nG | tr ' ' '\n' | grep -Fxq wheel; then
  die 'Текущий пользователь не состоит в wheel. Перед применением обеспечь себе доступ через sudo в новой конфигурации.'
fi
read -r -p 'Чтобы применить изменения на ЭТОМ ПК, введи APPLY: ' response
[[ "$response" == APPLY ]] || { say 'Не применено. Созданный host и результаты сборки сохранены.'; exit 0; }

new_user=0
id winarowk >/dev/null 2>&1 || new_user=1
if [[ "$repo" != /etc/nixos ]]; then
  backup="/etc/nixos.backup-$(date +%Y%m%d-%H%M%S)"
  [[ ! -e "$backup" && ! -L "$backup" ]] || die "Резервная копия $backup уже существует."
  if [[ -e /etc/nixos ]]; then
    sudo mv -- /etc/nixos "$backup"
    say "Старый конфиг сохранён: $backup"
  else
    backup=''
  fi
  if ! sudo cp -a -- "$repo" /etc/nixos; then
    say 'Копирование не завершилось. Система ещё не переключалась.'
    [[ -z "$backup" ]] || say "Старый конфиг находится в $backup; не удаляй его."
    die 'Остановлено. Проверь состояние /etc/nixos и резервной копии.'
  fi
  repo=/etc/nixos
fi
say 'Применяю конфиг. Git push не выполняется.'
if ! sudo env NIX_CONFIG="extra-experimental-features = nix-command flakes" nixos-rebuild switch --flake "$repo#$host"; then
  say 'Применение завершилось с ошибкой. Существующие файлы не удалялись.'
  [[ -z "${backup:-}" ]] || say "Старый конфиг: $backup"
  die 'Пришли полный текст ошибки; возможно, часть настроек успела примениться.'
fi
if (( new_user )); then
  say 'Пользователь winarowk создан без заданного пароля.'
  say 'Установи для него пароль перед выходом из текущей сессии:'
  say '  sudo passwd winarowk'
else
  say 'Существующий пароль winarowk не записывался в репозиторий.'
fi
say 'Готово. Следующая перезагрузка проверит запуск системы и загрузчика.'
say 'Внимание: обычная команда nrs из этого конфига коммитит и пушит изменения на GitHub.'
