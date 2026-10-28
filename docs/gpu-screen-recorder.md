# GPU Screen Recorder и NVIDIA 580

## Зачем нужен этот фикс

В логе Noctalia захват через portal/PipeWire уже запускается, но затем GSR
отказывает: драйвер поддерживает NVENC API 13.0, а сборка с FFmpeg 9 требует 13.1.
Это не ошибка прав доступа и не отсутствие H.264 у видеокарты.

Для GPU Screen Recorder выбран **FFmpeg 7 из того же nixpkgs**. Драйвер NVIDIA,
глобальный FFmpeg, Noctalia, настройки shell и порталы не меняются. Отдельный
старый снимок nixpkgs не добавляется, flake.lock не меняется.

## Где что находится

- `pkgs/gpu-screen-recorder-nvidia580.nix` — совместимый FFmpeg только у GSR.
- `modules/nixos/core/overlays.nix` — подмена backend для CLI, GTK и Noctalia.
- `modules/nixos/programs/media.nix` — GTK и включение NixOS-модуля с wrapper
  `gsr-kms-server`. Backend устанавливается самим модулем.

Не запускай GUI через sudo и не меняй setuid/capabilities вручную.
Ранее замеченная ошибка `pkexec must be setuid root` относилась к отдельной
Flatpak-версии, а не к этому исправлению нативного пакета.

## Временная проверка без изменения main

```sh
cd /etc/nixos
git fetch origin
git worktree add "$HOME/nixos-gsr-test" origin/fix/gsr-nvidia580-ffmpeg
sudo nixos-rebuild test --flake "$HOME/nixos-gsr-test#winarowk"
```

Если эта папка уже существует, не удаляй её вслепую: сначала проверь
`git -C "$HOME/nixos-gsr-test" status --short --branch`.

После успешного `test` выйди из графической сессии и войди снова, чтобы Noctalia
и launcher запустились с новым окружением. Проверь запись через плагин Noctalia.
Не запускай здесь `nrs`: он рассчитан на `/etc/nixos` и автоматически коммитит
и отправляет изменения.

`test` не делает конфигурацию загрузочной: при перезагрузке вернётся предыдущая
загрузочная конфигурация. После успешной проверки можно отдельно слить PR.

При повторной ошибке нужен свежий лог:

```sh
tail -n 80 "$HOME/.local/state/noctalia/screen_recorder/gpu-screen-recorder.log"
```

При изменённом `XDG_STATE_HOME` лог находится в нём, в том же подпути.

## Обновления и ограничения

FFmpeg 7 берётся из текущего flake.lock; остальные программы используют обычные
зависимости. При обновлении nixpkgs совместимость нужно перепроверять. После
перехода на другой драйвер необходимость этого workaround тоже стоит пересмотреть.
Часть пакетов может собираться локально — наличие любого пакета в nixpkgs
не гарантирует бинарный кэш для каждой комбинации зависимостей.

Проверка компиляции не заменяет реальную запись на NVIDIA: её нужно выполнить
на компьютере с этой видеокартой.
