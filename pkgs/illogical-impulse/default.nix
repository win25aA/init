# Только QML-оболочка end-4. Quickshell и зависимости — из общего nixpkgs.
# Установщик dots-hyprland и чужие настройки Hyprland/терминалов не запускаются.
{ lib, stdenvNoCC, fetchFromGitHub, bash, python3, quickshell, qt6, kdePackages,
  coreutils, findutils, gnugrep, gnused, gawk, procps, psmisc, util-linux,
  jq, bc, socat, curl, wget, ripgrep, wl-clipboard, cliphist, playerctl, wireplumber,
  brightnessctl, ddcutil, hyprland, hyprpicker, hyprshot, hyprsunset,
  grim, slurp, swappy, tesseract, gpu-screen-recorder, ffmpeg, imagemagick, mpvpaper, mpv, mpvScripts, matugen, fuzzel,
  translate-shell, libqalculate, songrec, ydotool, xkeyboard_config, sound-theme-freedesktop, gsettings-desktop-schemas,
  cava, libnotify, glib, gtk4, gnome-desktop, networkmanager,
  networkmanagerapplet, blueman, pavucontrol, upower, libsecret, kitty, btop,
  xdg-user-dirs, xdg-utils, lm_sensors, sysstat
}:
let
  python = python3.withPackages (p: with p; [
    pillow materialyoucolor numpy opencv4 click loguru tqdm pygobject3 requests psutil google-auth pywayland
  ]);
  runtime = [
    bash coreutils findutils gnugrep gnused gawk procps psmisc util-linux
    jq bc socat curl wget ripgrep wl-clipboard cliphist playerctl wireplumber
    brightnessctl ddcutil hyprland hyprpicker hyprshot hyprsunset
    grim slurp swappy tesseract gpu-screen-recorder ffmpeg imagemagick mpvpaper (mpv.override { scripts = [ mpvScripts.mpris ]; }) matugen fuzzel
    translate-shell libqalculate songrec ydotool
    cava libnotify glib networkmanager networkmanagerapplet blueman
    pavucontrol upower libsecret kitty btop xdg-user-dirs xdg-utils
    kdePackages.kdialog lm_sensors sysstat python
  ];
  qtModules = with qt6; [
    qtbase qtdeclarative qt5compat qtimageformats qtmultimedia qtpositioning
    qtquicktimeline qtsensors qtsvg qtvirtualkeyboard qtwayland
  ] ++ [ kdePackages.kirigami kdePackages.syntax-highlighting ];
  # kirigami — metapackage: его out содержит только nix-support, а QML
  # находится в kirigami.unwrapped и qqc2-desktop-style. Ручная обёртка,
  # в отличие от wrapQtAppsHook, должна сама включить propagated-зависимости.
  # propagatedBuildInputs могут ссылаться на dev-output; QML нужен из lib/out.
  qtRuntime = lib.unique (map (p: p.lib or p.out or p)
    (lib.closePropagation ([ quickshell ] ++ qtModules)));
  qmlPath = lib.makeSearchPath qt6.qtbase.qtQmlPrefix qtRuntime;
  pluginPath = lib.makeSearchPath qt6.qtbase.qtPluginPrefix qtRuntime;
in
stdenvNoCC.mkDerivation {
  pname = "illogical-impulse-shell";
  version = "unstable-2026-ii";
  src = fetchFromGitHub {
    owner = "end-4"; repo = "dots-hyprland";
    rev = "cb1c428bf841dabccff1b126904047c28e89ba8c";
    hash = "sha256-Yt87f7uf2qz1ZTRhWvqZ6h6ACvHagkzlm5EuNK00gnE=";
  };
  shapes = fetchFromGitHub {
    owner = "end-4"; repo = "rounded-polygon-qmljs";
    rev = "e31ec4cb4ebf6a46b267f5c42eabf6874916fa16";
    hash = "sha256-p1Ia0oQCWnik2saVMgv7IABkaJV43PoY7uuwXjXlc+Q=";
  };
  patches = [ ./nixos.patch ];
  dontBuild = true;
  dontConfigure = true;
  nativeBuildInputs = [ python ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/illogical-impulse" "$out/bin" "$out/libexec" "$out/python-env/bin"
    cp -R dots/.config/quickshell/ii/. "$out/share/illogical-impulse/"
    # Локальные вкладки ii в стиле оболочки.
    cp -R ${./overlay}/. "$out/share/illogical-impulse/"
    cp LICENSE "$out/share/illogical-impulse/LICENSE"
    cp -R "$shapes"/. "$out/share/illogical-impulse/modules/common/widgets/shapes/"
    cp -R dots/.config/matugen/templates "$out/share/illogical-impulse-matugen"
    cp -R dots/.config/hypr/hyprland/scripts "$out/share/illogical-impulse-hypr-scripts"
    chmod -R u+w "$out/share/illogical-impulse"
    substituteInPlace "$out/share/illogical-impulse/services/HyprlandXkb.qml" --replace-fail '@xkbRulesBase@' '${xkeyboard_config}/share/X11/xkb/rules/base.lst'
    substituteInPlace "$out/share/illogical-impulse/services/Audio.qml" --replace-fail '@soundsDir@' '${sound-theme-freedesktop}/share/sounds' 
    # Отсутствие shapes означает, что исходники получены без Git submodules.
    test -f "$out/share/illogical-impulse/modules/common/widgets/shapes/material-shapes.js"
    chmod -R u+w "$out/share/illogical-impulse"

    # NixOS не имеет /bin/bash; Python-скрипты также получают точный интерпретатор.
    python3 - "$out/share/illogical-impulse" <<'PY'
    import pathlib, sys
    for path in pathlib.Path(sys.argv[1]).rglob('*'):
        if not path.is_file() or path.suffix not in ('.py', '.sh'):
            continue
        text = path.read_text()
        if text.startswith('#!'):
            interpreter = '${python}/bin/python3' if path.suffix == '.py' else '${bash}/bin/bash'
            path.write_text('#!' + interpreter + '\n' + text.partition('\n')[2])
        path.chmod(path.stat().st_mode | 0o111)
    PY

    # Совместимость upstream-скриптов; это НЕ изменяемый pip/venv.
    cat > "$out/python-env/bin/activate" <<'ACTIVATE'
    export PATH="${python}/bin:$PATH"
    deactivate() { :; }
    ACTIVATE

    cat > "$out/libexec/environment" <<'ENV'
    export PATH="@out@/libexec:${lib.makeBinPath runtime}:$PATH"
    export QML_IMPORT_PATH="${qmlPath}''${QML_IMPORT_PATH:+:$QML_IMPORT_PATH}"
    export QML2_IMPORT_PATH="${qmlPath}''${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"
    export QT_PLUGIN_PATH="${pluginPath}''${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
    export GI_TYPELIB_PATH="${lib.makeSearchPath "lib/girepository-1.0" [ gnome-desktop glib gtk4 ]}''${GI_TYPELIB_PATH:+:$GI_TYPELIB_PATH}"
    export XDG_DATA_DIRS="${lib.makeSearchPath "share" [ glib gtk4 gnome-desktop ]}:${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}:''${XDG_DATA_DIRS:-/run/current-system/sw/share:$HOME/.nix-profile/share}"
    export ILLOGICAL_IMPULSE_VIRTUAL_ENV="@out@/python-env"
    ENV
    substituteInPlace "$out/libexec/environment" --replace-fail '@out@' "$out"

    cat > "$out/libexec/qs" <<'QS'
    #!${bash}/bin/bash
    source @out@/libexec/environment
    exec ${quickshell}/bin/quickshell "$@"
    QS
    cat > "$out/bin/ii-shell" <<'SHELL'
    #!${bash}/bin/bash
    source @out@/libexec/environment
    state="''${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/user/generated"
    mkdir -p "$state/wallpaper" "''${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprland"
    # Только для сессии Hyprland: освободить D-Bus уведомлений перед стартом ii.
    # Не трогаем другие службы и не меняем автозапуск Noctalia в Sway.
    if [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
      owner_pid=$(gdbus call --session --dest org.freedesktop.DBus \
        --object-path /org/freedesktop/DBus \
        --method org.freedesktop.DBus.GetConnectionUnixProcessID org.freedesktop.Notifications 2>/dev/null \
        | sed -n 's/.*uint32 \([0-9][0-9]*\).*/\1/p')
      if [ -n "$owner_pid" ] && [ -r "/proc/$owner_pid/comm" ] \
        && [ "$(stat -c %u "/proc/$owner_pid" 2>/dev/null)" = "$(id -u)" ]; then
        case "$(cat "/proc/$owner_pid/comm")" in
          dunst|mako)
            kill "$owner_pid" 2>/dev/null || true
            for _ in 1 2 3 4 5 6 7 8 9 10; do
              kill -0 "$owner_pid" 2>/dev/null || break
              sleep 0.1
            done
            ;;
        esac
      fi
    fi
    config="''${XDG_CONFIG_HOME:-$HOME/.config}/illogical-impulse/config.json"
    image=$(jq -r '.background.wallpaperPath // empty' "$config")
    if [ ! -s "$state/colors.json" ] && [ -f "$image" ]; then
      matugen image "$image" --source-color-index 0 --mode dark --type scheme-content || echo 'ii: initial palette failed' >&2
    fi
    exec qs -c ii "$@"
    SHELL
    # IPC для Hyprland: системный PATH не обязан содержать qs.
    cat > "$out/bin/ii-ipc" <<'IPC'
    #!${bash}/bin/bash
    source @out@/libexec/environment
    exec ${quickshell}/bin/quickshell -c ii ipc call "$@"
    IPC
    # wl-paste и cliphist тоже доступны только внутри окружения ii.
    cat > "$out/bin/ii-clipboard-watch" <<'CLIP'
    #!${bash}/bin/bash
    source @out@/libexec/environment
    exec wl-paste --type "$1" --watch bash -c 'cliphist store && qs -c ii ipc call cliphistService update'
    CLIP
    cat > "$out/bin/ii-screenshot-full" <<'SHOT'
    #!${bash}/bin/bash
    source @out@/libexec/environment
    monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')
    [ -n "$monitor" ] && grim -o "$monitor" - | wl-copy
    SHOT
    for file in "$out/libexec/qs" "$out/bin/ii-shell" "$out/bin/ii-ipc" "$out/bin/ii-clipboard-watch" "$out/bin/ii-screenshot-full"; do
      substituteInPlace "$file" --replace '@out@' "$out"
      chmod +x "$file"
    done
    runHook postInstall
  '';

  # Не выпускать пакет, если пути QML снова потеряются при обновлении nixpkgs.
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    for module in org/kde/kirigami org/kde/syntaxhighlighting Qt5Compat/GraphicalEffects QtPositioning; do
      found=false
      for base in ${lib.concatStringsSep " " (map (p: "${p}/${qt6.qtbase.qtQmlPrefix}") qtRuntime)}; do
        if [ -f "$base/$module/qmldir" ]; then
          found=true
          break
        fi
      done
      if [ "$found" != true ]; then
        echo "Required QML module is missing from the QS runtime: $module" >&2
        exit 1
      fi
    done
    runHook postInstallCheck
  '';

  meta = {
    description = "end-4 illogical-impulse QS shell, isolated from personal Hyprland and app configuration";
    homepage = "https://github.com/end-4/dots-hyprland";
    license = lib.licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "ii-shell";
  };
}
