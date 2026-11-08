#!/usr/bin/env bash
# Подготовка общего конфига для уже установленной NixOS. Диски не форматирует.
set -Eeuo pipefail

# --check исключает применение, перенос конфига и запись загрузчика.
check_only=false
if (( $# > 1 )); then
  echo 'Использование: bash setup-new-pc.sh [--check]' >&2
  exit 1
fi
case "${1:-}" in
  '') ;;
  --check) check_only=true ;;
  *) echo 'Использование: bash setup-new-pc.sh [--check]' >&2; exit 1 ;;
esac

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
[[ "$(uname -m)" == x86_64 ]] || die 'Этот flake сейчас рассчитан только на x86_64; настройки не созданы.'
for cmd in git nix sudo nixos-generate-config nixos-rebuild lsblk findmnt realpath; do
  command -v "$cmd" >/dev/null || die "Не найдена команда $cmd. Если нет Git: nix-shell -p git"
done
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo=$(git -C "$script_dir" rev-parse --show-toplevel 2>/dev/null) || die 'Запусти скрипт из клонированного Git-репозитория.'
repo=$(realpath "$repo")
[[ -d "$repo/.git" && ! -L "$repo/.git" ]] || die 'Нужна обычная копия репозитория, а не Git worktree или симлинк .git.'
[[ "$repo" != *$'\n'* ]] || die 'Путь к конфигу не должен содержать перевод строки.'
case "$repo/" in /etc/nixos/*) [[ "$repo" == /etc/nixos ]] || die 'Копия лежит внутри /etc/nixos. Перемести её за пределы этой папки и попробуй снова.';; esac

if $check_only; then
  say 'Режим проверки: host и Git staging меняются только в этой копии; система не переключается, загрузчик не записывается.'
fi
say 'Этот скрипт для уже установленной NixOS. Он не форматирует диски и не делает git push.'
say 'Он создаст новый host, проверит сборку и только с твоего подтверждения применит конфиг.'
say 'Общие программы и настройки берутся из этого репозитория; существующий конфиг будет сохранён.'
say 'Важно: при применении системные службы и настройки заменятся настройками этого конфига.'
say 'Создай резервную копию важных данных перед применением. На новом ПК нужен доступ к интернету.'
say 'Wi-Fi-пароли, аккаунты и данные программ скрипт не переносит.'
say 'Съёмные или не подключённые диски могут не попасть в сгенерированный список.'
say
# Проверяем известный риск: для зашифрованного корня требуется отдельная
# конфигурация разблокировки в initrd, генератор файловых систем её не переносит.
root_source=$(findmnt -n -o SOURCE --mountpoint / 2>/dev/null || true)
root_device=${root_source%%\[*}
root_encrypted=false
if [[ "$root_device" == /dev/* && -b "$root_device" ]]; then
  root_types=$(lsblk -snr -o TYPE -- "$root_device" 2>/dev/null || true)
  if grep -Fxq crypt <<< "$root_types"; then root_encrypted=true; fi
fi
if $root_encrypted; then
  say 'Похоже, корневой диск зашифрован. Настройка его разблокировки автоматически не переносится.'
  if ! $check_only; then
    die 'Автоматическое применение остановлено: сначала нужна ручная проверка LUKS/initrd. Система не менялась.'
  fi
  say 'Режим --check может проверить только сборку, а не загрузку зашифрованного диска.'
fi

current_hostname=$(hostname -s 2>/dev/null || true)
if [[ ! "$current_hostname" =~ ^[a-z][a-z0-9-]{0,62}$ || "$current_hostname" == *- ]]; then current_hostname=pc; fi
read -r -p "Имя нового ПК [$current_hostname]: " host
host=${host:-$current_hostname}
[[ "$host" =~ ^[a-z][a-z0-9-]{0,62}$ && "$host" != *- ]] || die 'Имя: строчные латинские буквы, цифры и дефис; начать с буквы, не заканчивать дефисом.'
hostdir="$repo/hosts/$host"
[[ ! -e "$hostdir" && ! -L "$hostdir" ]] || die "Папка hosts/$host уже есть. Она не будет перезаписана; выбери другое имя."

# Определяем PCI-видеокарты; точную совместимость драйвера не угадываем.
declare -A vendors=() addresses=()
gpu_count=0
say 'Обнаруженные PCI-видеокарты (vendor:device):'
for dev in /sys/bus/pci/devices/*; do
  [[ -r "$dev/class" && -r "$dev/vendor" && -r "$dev/device" ]] || continue
  read -r class < "$dev/class" || continue
  [[ "$class" == 0x03* ]] || continue
  read -r vendor < "$dev/vendor" || continue
  read -r device < "$dev/device" || continue
  printf '  %s: %s:%s\n' "${dev##*/}" "$vendor" "$device"
  ((gpu_count+=1))
  case "$vendor" in
    0x10de) vendors[nvidia]=1; addresses[nvidia]=${dev##*/} ;;
    0x1002) vendors[amd]=1; addresses[amd]=${dev##*/} ;;
    0x8086) vendors[intel]=1; addresses[intel]=${dev##*/} ;;
  esac
done
if command -v lspci >/dev/null; then lspci -nn | grep -iE 'VGA compatible|3D controller|Display controller' || true; fi
prime_enabled=false
prime_integrated=intel
prime_igpu_bus=''
prime_nvidia_bus=''
pci_bus_id() {
  local address=$1
  [[ "$address" =~ ^([[:xdigit:]]{4}):([[:xdigit:]]{2}):([[:xdigit:]]{2})\.([0-7])$ ]] || return 1
  printf 'PCI:%d@%d:%d:%d' "$((16#${BASH_REMATCH[2]}))" "$((16#${BASH_REMATCH[1]}))" "$((16#${BASH_REMATCH[3]}))" "$((16#${BASH_REMATCH[4]}))"
}
if [[ -n "${vendors[nvidia]:-}" ]] && (( gpu_count > 1 )); then
  if (( gpu_count != 2 || ${#vendors[@]} != 2 )) || [[ -z "${vendors[intel]:-}${vendors[amd]:-}" ]]; then
    die 'Несколько видеокарт: не удалось однозначно определить пару NVIDIA и встроенной Intel/AMD. Нужна ручная настройка.'
  fi
  gpu=nvidia
  [[ -z "${vendors[amd]:-}" ]] || prime_integrated=amd
  prime_igpu_bus=$(pci_bus_id "${addresses[$prime_integrated]}") || die 'Не удалось распознать адрес встроенной графики.'
  prime_nvidia_bus=$(pci_bus_id "${addresses[nvidia]}") || die 'Не удалось распознать адрес NVIDIA.'
  say "Найдена пара NVIDIA + $prime_integrated: $prime_nvidia_bus и $prime_igpu_bus."
  say 'Вариант PRIME Offload: рабочий стол на встроенной графике, отдельные программы на NVIDIA через nvidia-offload.'
  say 'Он подходит не всему железу; мониторы, подключённые прямо к NVIDIA, могут потребовать другой настройки.'
  say 'Проверь модели и совместимость: https://wiki.nixos.org/wiki/NVIDIA#Offload_mode'
  confirm 'Подтверждаешь, что это встроенная графика + NVIDIA и они поддерживают PRIME Offload?' || die 'PRIME не подтверждён; host не создан.'
  prime_enabled=true
elif (( gpu_count == 1 && ${#vendors[@]} == 1 )); then
  for gpu in "${!vendors[@]}"; do :; done
else
  say 'Однозначно определить видеокарту не удалось. Посмотри PCI ID выше.'
  read -r -p 'Укажи тип (nvidia / amd / intel / other), или q для выхода: ' gpu
fi
case "$gpu" in nvidia|amd|intel|other) ;; *) die 'Видеокарта не выбрана; host не создан.';; esac
if [[ "$gpu" == nvidia ]] && (( gpu_count > 1 )) && ! $prime_enabled; then
  die 'Несколько видеокарт с выбранной NVIDIA: нужна ручная проверка; host не создан.'
fi
nvidia_driver=legacy_580
nvidia_open=false
if [[ "$gpu" == nvidia ]]; then
  say 'Выбери драйвер ПОСЛЕ проверки модели и списка поддерживаемых карт NVIDIA:'
  say '  1 — 580, закрытый модуль (например, GTX 1050 Ti)'
  say '  2 — stable, открытый модуль ядра NVIDIA (только поддерживаемые карты)'
  say '  3 — stable, закрытый модуль (только поддерживаемые карты)'
  say '  q — выйти, если не знаешь или нужен другой драйвер'
  say 'Список 580: https://download.nvidia.com/XFree86/Linux-x86_64/580.178.04/README/supportedchips.html'
  say 'Stable зависит от версии nixpkgs в flake.lock; его совместимость тоже нужно проверить.'
  read -r -p 'Твой выбор [1/2/3/q]: ' driver_choice
  case "$driver_choice" in
    1) nvidia_driver=legacy_580; nvidia_open=false ;;
    2) nvidia_driver=stable; nvidia_open=true ;;
    3) nvidia_driver=stable; nvidia_open=false ;;
    *) die 'Драйвер не выбран; host не создан.' ;;
  esac
  confirm 'Ты проверила, что выбранные ветка и тип модуля поддерживают эту карту?' || die 'Совместимость не подтверждена; host не создан.'
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
[[ "$gpu" != nvidia ]] || say "NVIDIA: $nvidia_driver, открытый модуль ядра: $nvidia_open, PRIME Offload: $prime_enabled."
say 'Пользователь нового конфига: winarowk. Общий список программ не меняется.'
confirm 'Создать host и проверить сборку?' || die 'Отменено; настройки не созданы.'

mkdir -- "$hostdir"
if ! sudo nixos-generate-config --show-hardware-config > "$hostdir/hardware-configuration.nix"; then
  die "Не удалось получить конфигурацию железа. Папка hosts/$host оставлена для проверки; существующие файлы не менялись."
fi
cat > "$hostdir/default.nix" <<NIX
# Создано setup-new-pc.sh для этого компьютера.
{ lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../system
  ];

  my.noctaliaSettingsFile = "/etc/nixos/hosts/$host/noctalia-settings.toml";
  my.gpu = "$gpu";
  my.nvidia.driver = "$nvidia_driver";
  my.nvidia.open = $nvidia_open;
  my.nvidia.prime = {
    enable = $prime_enabled;
    integratedGpu = "$prime_integrated";
    integratedBusId = "$prime_igpu_bus";
    nvidiaBusId = "$prime_nvidia_bus";
  };
  my.boot = {
    mode = "$mode";
    grubDevice = "$grub_device";
  };

  # Noctalia сохраняет настройки обоев в личный файл этого хоста.
  # Не меняем права остальных файлов репозитория.
  systemd.tmpfiles.rules = [
    "z /etc/nixos/hosts/$host - winarowk - - -"
    "z /etc/nixos/hosts/$host/noctalia-settings.toml - winarowk - - -"
  ];

  # Hyprland и Sway включают мониторы без привязки к старому ПК.
  system.stateVersion = "$state_version";
}
NIX

# Для нового ПК личная копия настроек GUI: исходный файл старого ПК не меняем.
# Пустой output у desktop-виджета позволяет Noctalia выбрать доступный экран.
if ! awk '
  /^[[:space:]]*\[/ { widget = ($0 ~ /^[[:space:]]*\[desktop_widgets\.widget\.[^]]+\]/) }
  widget && /^[[:space:]]*output[[:space:]]*=/ { sub(/=.*/, "= \"\"") }
  { print }
' "$repo/home/noctalia/settings.toml" > "$hostdir/noctalia-settings.toml"; then
  die "Не удалось создать настройки Noctalia в hosts/$host. Система не менялась."
fi

# Генератор иногда выводит systemd automount и сам раздел как два
# fileSystems для одного пути. Убираем только точно распознанную пару:
# обычный блок реального устройства + простой служебный autofs-блок.
tmp_hw=$(mktemp "$hostdir/.hardware-configuration.XXXXXX")
if ! awk '
  { lines[NR] = $0 }
  END {
    for (i = 1; i <= NR; i++) {
      if (lines[i] ~ /^[[:space:]]*fileSystems\."[^"]+"[[:space:]]*=[[:space:]]*$/) {
        name = lines[i]; sub(/^[[:space:]]*fileSystems\."/, "", name); sub(/"[[:space:]]*=.*$/, "", name)
        count[name]++
        if (lines[i+1] ~ /^[[:space:]]*\{[[:space:]]*device[[:space:]]*=[[:space:]]*"systemd-1";[[:space:]]*$/ &&
            lines[i+2] ~ /^[[:space:]]*fsType[[:space:]]*=[[:space:]]*"autofs";[[:space:]]*$/ &&
            lines[i+3] ~ /^[[:space:]]*\};[[:space:]]*$/) {
          auto[name]++; auto_line[name] = i
        } else if (lines[i+1] ~ /^[[:space:]]*\{[[:space:]]*device[[:space:]]*=[[:space:]]*"\/dev\/[^" ]+";[[:space:]]*$/ &&
                   lines[i+2] ~ /^[[:space:]]*fsType[[:space:]]*=[[:space:]]*"[^" ]+";[[:space:]]*$/ &&
                   lines[i+2] !~ /"autofs"/ && lines[i+3] ~ /^[[:space:]]*\};[[:space:]]*$/) {
          disk[name]++
        }
      }
    }
    for (name in count) if (count[name] == 2 && auto[name] == 1 && disk[name] == 1)
      for (j = auto_line[name]; j <= auto_line[name]+3; j++) skip[j] = 1
    for (i = 1; i <= NR; i++) if (!skip[i]) print lines[i]
  }
' "$hostdir/hardware-configuration.nix" > "$tmp_hw"; then
  die "Не удалось проверить настройки дисков. Проверь hosts/$host; система не менялась."
fi
if ! cmp -s "$hostdir/hardware-configuration.nix" "$tmp_hw"; then
  say 'Убран служебный дубль systemd autofs; блок самого диска оставлен.'
  say 'Сейчас проверю параметры fstab; сложные случаи требуют ручной проверки.'
fi
mv -- "$tmp_hw" "$hostdir/hardware-configuration.nix"

# Безопасно переносим распространённые настройки дополнительных локальных
# дисков из действующего fstab. Сложные варианты не угадываем и не печатаем
# неизвестные параметры: в них могут быть секреты.
mount_overrides=$(mktemp "$hostdir/.mount-options.XXXXXX")
needs_mount_review=false
declare -A seen_mounts=()
if [[ -r /etc/fstab ]]; then
  while read -r source target fstype opts rest; do
    [[ -n "${source:-}" && "$source" != \#* ]] || continue
    case "${target:-}" in
      /|/boot|/boot/efi|none) continue ;;
      /mnt/*) ;;
      *)
        say 'Найдена файловая система вне /mnt: автоматический перенос её параметров не поддерживается.'
        needs_mount_review=true
        continue ;;
    esac
    if [[ ! "$target" =~ ^/mnt/[[:alnum:]_./-]+$ || "$target" == *..* ]]; then
      say 'Найдена сложная точка монтирования в fstab; нужна ручная проверка.'
      needs_mount_review=true
      continue
    fi
    if [[ -n "${seen_mounts[$target]:-}" ]]; then
      say 'В fstab повторяется точка монтирования; нужна ручная проверка.'
      needs_mount_review=true
      continue
    fi
    seen_mounts[$target]=1
    safe=true
    case "$source" in
      UUID=*) uuid=${source#UUID=} ;;
      /dev/disk/by-uuid/*) uuid=${source#/dev/disk/by-uuid/} ;;
      *) safe=false; uuid='' ;;
    esac
    [[ "$uuid" =~ ^[[:alnum:]-]+$ && "$target" =~ ^/mnt/[[:alnum:]_./-]+$ && "$target" != *..* ]] || safe=false
    case "$fstype" in ext4|btrfs|xfs|vfat|exfat|ntfs3) ;; *) safe=false ;; esac
    options_nix=''
    IFS=, read -r -a mount_opts <<< "${opts:-}"
    for opt in "${mount_opts[@]}"; do
      case "$opt" in
        defaults|users|user|nouser|nofail|noauto|auto|exec|noexec|rw|ro|noatime|relatime|nodiratime|nosuid|suid|nodev|dev|x-systemd.automount) ;;
        *) safe=false ;;
      esac
      options_nix+=" \"$opt\""
    done
    # Отключённый диск разрешаем переносить только с nofail.
    [[ ",$opts," == *,nofail,* ]] || safe=false
    if ! $safe; then
      say "Диск $target требует ручной проверки fstab (тип, источник или параметры не распознаны)."
      needs_mount_review=true
      continue
    fi
    device="/dev/disk/by-uuid/$uuid"
    generated=$(awk -v target="$target" '
      $0 ~ /^[[:space:]]*fileSystems\."/ {
        line=$0; sub(/^[[:space:]]*fileSystems\."/, "", line); sub(/".*/, "", line); inblock=(line == target)
      }
      inblock && /device[[:space:]]*=/ { x=$0; sub(/^.*device[[:space:]]*=[[:space:]]*"/, "", x); sub(/".*/, "", x); print x; exit }
    ' "$hostdir/hardware-configuration.nix")
    generated_type=$(awk -v target="$target" '
      $0 ~ /^[[:space:]]*fileSystems\."/ {
        line=$0; sub(/^[[:space:]]*fileSystems\."/, "", line); sub(/".*/, "", line); inblock=(line == target)
      }
      inblock && /fsType[[:space:]]*=/ { x=$0; sub(/^.*fsType[[:space:]]*=[[:space:]]*"/, "", x); sub(/".*/, "", x); print x; exit }
    ' "$hostdir/hardware-configuration.nix")
    if [[ -n "$generated" && ( "$generated" != "$device" || "$generated_type" != "$fstype" ) ]]; then
      say "Диск $target: устройство или тип в fstab не совпали с обнаруженными; нужна ручная проверка."
      needs_mount_review=true
      continue
    fi
    if [[ -z "$generated" ]]; then
      printf '  fileSystems."%s".device = "%s";\n  fileSystems."%s".fsType = "%s";\n' "$target" "$device" "$target" "$fstype" >> "$mount_overrides"
    fi
    printf '  fileSystems."%s".options = lib.mkForce [%s ];\n' "$target" "$options_nix" >> "$mount_overrides"
    say "Перенесены параметры fstab для $target."
  done < /etc/fstab
else
  say 'Не удалось прочитать /etc/fstab; параметры существующих дисков нужно проверить вручную.'
  needs_mount_review=true
fi
if [[ -s "$mount_overrides" ]]; then
  tmp_default=$(mktemp "$hostdir/.default.XXXXXX")
  sed '$d' "$hostdir/default.nix" > "$tmp_default"
  say 'Параметры дополнительных дисков, добавленные в host:'
  cat "$mount_overrides"
  cat "$mount_overrides" >> "$tmp_default"
  printf '}\n' >> "$tmp_default"
  mv -- "$tmp_default" "$hostdir/default.nix"
fi
rm -- "$mount_overrides"

say
say 'Обнаруженные настройки файловых систем и дисков:'
grep -A 5 -E 'fileSystems\.|swapDevices' "$hostdir/hardware-configuration.nix" || true
say 'Проверь все диски, особенно дополнительные и съёмные. Параметры / и /boot также надо сверить со старым конфигом.'
if $needs_mount_review; then
  die "Не все дополнительные диски удалось перенести безопасно. Проверь hosts/$host вручную; система не менялась."
fi
# nixos-generate-config иногда дважды показывает одну точку монтирования
# (например, systemd automount). Удалять один из блоков без проверки нельзя.
duplicates=$(sed -nE 's/^[[:space:]]*fileSystems\."([^"]+)"[[:space:]]*=.*/\1/p' "$hostdir/hardware-configuration.nix" | sort | uniq -d)
if [[ -n "$duplicates" ]]; then
  say 'Найдены повторяющиеся точки монтирования:'
  say "$duplicates"
  die "Проверь и исправь дубли в hosts/$host/hardware-configuration.nix. Host сохранён; система не менялась."
fi
if grep -qE '^[[:space:]]*fsType[[:space:]]*=[[:space:]]*"autofs";' "$hostdir/hardware-configuration.nix"; then
  die "Остался служебный autofs, который нельзя безопасно распознать. Проверь hosts/$host/hardware-configuration.nix вручную."
fi
confirm 'Продолжить сборку?' || die "Остановлено. Папка hosts/$host сохранена для проверки."
# Flake в Git не видит неотслеживаемые файлы. Staging не создаёт коммит и не пушит.
git -C "$repo" add -- "hosts/$host/default.nix" "hosts/$host/hardware-configuration.nix" "hosts/$host/noctalia-settings.toml"
say 'Проверяю сборку; это может занять время. Система пока не переключается.'
nix --extra-experimental-features 'nix-command flakes' build --no-link "$repo#nixosConfigurations.$host.config.system.build.toplevel" || die "Сборка не прошла. Host оставлен в hosts/$host, существующая система не переключалась."

say
if $check_only; then
  say 'Проверка завершена: сборка прошла, система не переключалась и загрузчик не менялся.'
  exit 0
fi
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
  say 'UEFI: проверь, что /boot — нужный EFI-раздел. GRUB может изменить записи загрузки UEFI.'
  secure_state=''
  if command -v mokutil >/dev/null; then secure_state=$(LC_ALL=C mokutil --sb-state 2>/dev/null || true); fi
  if [[ "$secure_state" == *'SecureBoot enabled'* ]]; then
    die 'Secure Boot включён. Для этого конфига нужна отдельная настройка подписанной загрузки; автоматически применять не буду.'
  elif [[ "$secure_state" != *'SecureBoot disabled'* ]]; then
    say 'Не удалось проверить Secure Boot. Включённый Secure Boot может не загрузить этот конфиг.'
    confirm 'Ты проверила, что Secure Boot отключён?' || die 'Secure Boot не подтверждён; конфиг не применён.'
  fi
  confirm 'Это правильный EFI-раздел для загрузчика?' || die 'EFI-раздел не подтверждён; конфиг не применён.' 
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
  staged="/etc/nixos.new-$(date +%Y%m%d-%H%M%S)"
  [[ ! -e "$staged" && ! -L "$staged" ]] || die "Временный путь $staged уже существует."
  if ! sudo cp -a -- "$repo" "$staged"; then
    die "Копия не завершена: $staged. Старый /etc/nixos не тронут; систему не переключали."
  fi
  if [[ -e /etc/nixos ]]; then
    sudo mv -- /etc/nixos "$backup"
    say "Старый конфиг сохранён: $backup"
  else
    backup=''
  fi
  if ! sudo mv -- "$staged" /etc/nixos; then
    if [[ -n "$backup" && ! -e /etc/nixos && ! -L /etc/nixos ]]; then
      sudo mv -- "$backup" /etc/nixos && say 'Старый конфиг возвращён в /etc/nixos.'
    fi
    die "Не удалось переместить новый конфиг. Система не переключалась; проверь $staged и ${backup:-/etc/nixos}."
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
say 'Готово. После перезагрузки выполни ncheck в fish и проверь графику, звук и сеть.'
say 'nrs после сборки покажет изменения и попросит подтверждение перед коммитом и push.'
