# Только QML-оболочка end-4. Quickshell и зависимости — из общего nixpkgs.
# Установщик dots-hyprland и чужие настройки Hyprland/терминалов не запускаются.
{ lib, stdenvNoCC, src, bash, python3, quickshell, qt6, kdePackages,
  coreutils, findutils, gnugrep, gnused, gawk, procps, psmisc, util-linux,
  jq, bc, curl, wget, ripgrep, wl-clipboard, cliphist, playerctl, wireplumber,
  brightnessctl, ddcutil, hyprland, hyprpicker, hyprshot, hyprsunset,
  grim, slurp, swappy, tesseract, wf-recorder, ffmpeg, imagemagick, mpvpaper,
  cava, libnotify, glib, gtk4, gnome-desktop, networkmanager,
  networkmanagerapplet, blueman, pavucontrol, upower, libsecret, kitty, btop,
  xdg-user-dirs, xdg-utils, lm_sensors, sysstat
}:
let
  python = python3.withPackages (p: with p; [
    pillow materialyoucolor numpy opencv4 click loguru tqdm pygobject3 requests psutil
  ]);
  runtime = [
    bash coreutils findutils gnugrep gnused gawk procps psmisc util-linux
    jq bc curl wget ripgrep wl-clipboard cliphist playerctl wireplumber
    brightnessctl ddcutil hyprland hyprpicker hyprshot hyprsunset
    grim slurp swappy tesseract wf-recorder ffmpeg imagemagick mpvpaper
    cava libnotify glib networkmanager networkmanagerapplet blueman
    pavucontrol upower libsecret kitty btop xdg-user-dirs xdg-utils
    kdePackages.kdialog lm_sensors sysstat python
  ];
  qtModules = with qt6; [
    qtbase qtdeclarative qt5compat qtimageformats qtmultimedia qtpositioning
    qtquicktimeline qtsensors qtsvg qtvirtualkeyboard qtwayland
  ] ++ [ kdePackages.kirigami kdePackages.syntax-highlighting ];
  qmlPath = lib.makeSearchPath qt6.qtbase.qtQmlPrefix ([ quickshell ] ++ qtModules);
  pluginPath = lib.makeSearchPath qt6.qtbase.qtPluginPrefix qtModules;
in
stdenvNoCC.mkDerivation {
  pname = "illogical-impulse-shell";
  version = "unstable-${builtins.substring 0 8 (src.rev or "unknown")}";
  inherit src;
  patches = [ ./shell-only.patch ];
  dontBuild = true;
  dontConfigure = true;
  nativeBuildInputs = [ python ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/illogical-impulse" "$out/bin" "$out/libexec" "$out/python-env/bin"
    cp -R dots/.config/quickshell/ii/. "$out/share/illogical-impulse/"
    cp LICENSE "$out/share/illogical-impulse/LICENSE"
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

    cp ${./seed-settings.py} "$out/bin/ii-seed-settings"
    cp ${./write-colors.py} "$out/bin/ii-write-colors"
    for file in "$out/bin/ii-seed-settings" "$out/bin/ii-write-colors"; do
      sed -i '1c#!${python}/bin/python3' "$file"
      chmod +x "$file"
    done
    # Совместимость upstream-скриптов; это НЕ изменяемый pip/venv.
    cat > "$out/python-env/bin/activate" <<'ACTIVATE'
    export PATH="${python}/bin:$PATH"
    deactivate() { :; }
    ACTIVATE

    cat > "$out/libexec/environment" <<'ENV'
    export PATH="@out@/bin:${lib.makeBinPath runtime}:$PATH"
    export QML_IMPORT_PATH="${qmlPath}''${QML_IMPORT_PATH:+:$QML_IMPORT_PATH}"
    export QML2_IMPORT_PATH="${qmlPath}''${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"
    export QT_PLUGIN_PATH="${pluginPath}''${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
    export GI_TYPELIB_PATH="${lib.makeSearchPath "lib/girepository-1.0" [ gnome-desktop glib gtk4 ]}''${GI_TYPELIB_PATH:+:$GI_TYPELIB_PATH}"
    export XDG_DATA_DIRS="${lib.makeSearchPath "share" [ glib gtk4 gnome-desktop ]}:''${XDG_DATA_DIRS:-/run/current-system/sw/share:$HOME/.nix-profile/share}"
    export ILLOGICAL_IMPULSE_VIRTUAL_ENV="@out@/python-env"
    export II_WALLPAPER_DIR="/etc/nixos/wallpapers"
    export II_DEFAULT_WALLPAPER="@out@/share/illogical-impulse/assets/images/default_wallpaper.png"
    ENV
    substituteInPlace "$out/libexec/environment" --replace-fail '@out@' "$out"

    cat > "$out/bin/qs" <<'QS'
    #!${bash}/bin/bash
    source @out@/libexec/environment
    exec ${quickshell}/bin/quickshell "$@"
    QS
    cat > "$out/bin/ii-shell" <<'SHELL'
    #!${bash}/bin/bash
    set -e
    source @out@/libexec/environment
    ii-seed-settings
    state="''${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/user/generated"
    config="''${XDG_CONFIG_HOME:-$HOME/.config}/illogical-impulse/config.json"
    # Первую палитру создаём без hyprctl, смены обоев или тем других программ.
    if [ ! -s "$state/colors.json" ]; then
      mkdir -p "$state"
      image=$(jq -r '.background.wallpaperPath // empty' "$config")
      [ -f "$image" ] || image="$II_DEFAULT_WALLPAPER"
      if ${python}/bin/python3 @out@/share/illogical-impulse/scripts/colors/generate_colors_material.py \
        --path "$image" --mode dark --scheme scheme-tonal-spot > "$state/material_colors.scss.tmp"; then
        mv "$state/material_colors.scss.tmp" "$state/material_colors.scss"
        ii-write-colors "$state/material_colors.scss" "$state/colors.json"
      else
        rm -f "$state/material_colors.scss.tmp"
        echo "QS: initial palette failed; using the built-in palette" >&2
      fi
    fi
    exec qs -c ii "$@"
    SHELL
    cat > "$out/bin/ii-panel" <<'PANEL'
    #!${bash}/bin/bash
    set -e
    source @out@/libexec/environment
    case "''${1:-}" in
      launcher)       exec qs -c ii ipc call search toggle ;;
      wallpaper)      exec qs -c ii ipc call wallpaperSelector toggle ;;
      session)        exec qs -c ii ipc call session toggle ;;
      control-center) exec qs -c ii ipc call sidebarRight toggle ;;
      screenshot-fullscreen) exec hyprshot -m output --clipboard-only ;;
      screenshot-region)     exec hyprshot -m region --clipboard-only ;;
      *) echo 'Usage: ii-panel {launcher|wallpaper|session|control-center|screenshot-fullscreen|screenshot-region}' >&2; exit 2 ;;
    esac
    PANEL
    cat > "$out/bin/ii-update-info" <<'UPDATE'
    #!${bash}/bin/bash
    exec ${libnotify}/bin/notify-send 'NixOS' 'Обновление: cd /etc/nixos → nix flake update → nixos-rebuild. См. README. Arch/pacman здесь не используется.'
    UPDATE
    for file in "$out/bin/qs" "$out/bin/ii-shell" "$out/bin/ii-panel" "$out/bin/ii-update-info"; do
      substituteInPlace "$file" --replace '@out@' "$out"
      chmod +x "$file"
    done
    runHook postInstall
  '';

  meta = {
    description = "end-4 illogical-impulse QS shell, isolated from personal Hyprland and app configuration";
    homepage = "https://github.com/end-4/dots-hyprland";
    license = lib.licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "ii-shell";
  };
}
