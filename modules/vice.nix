{ config, pkgs, lib, inputs, ... }:

let
  # Vice - запись игровых клипов (аналог Medal.tv / ShadowPlay)
  # https://github.com/eklonofficial/Vice
  vice = pkgs.python3Packages.buildPythonApplication {
    pname = "vice";
    version = "1.3.4";
    pyproject = true;

    src = inputs.vice-src;

    build-system = with pkgs.python3Packages; [ setuptools wheel ];

    dependencies = with pkgs.python3Packages; [
      evdev
      aiohttp
      click
      tomli-w
      psutil
      pywebview
    ];

    # UI на pywebview (Qt/PySide6) - нужно квалифицированное Qt-окружение
    nativeBuildInputs = [ pkgs.qt6.wrapQtAppsHook ];
    dontWrapQtApps = true;
    preFixup = ''
      makeWrapperArgs+=("''${qtWrapperArgs[@]}")
    '';

    # Бинарники, которые vice вызывает в рантайме.
    # gpu-screen-recorder намеренно НЕ здесь: он берётся из системного PATH,
    # где лежит версия с setcap-обёрткой (programs.gpu-screen-recorder).
    makeWrapperArgs = [
      "--prefix PATH : ${lib.makeBinPath (with pkgs; [
        ffmpeg        # обрезка/склейка клипов (+ffprobe)
        wf-recorder   # запасной бэкенд записи
        cloudflared   # публичные share-ссылки
        wl-clipboard  # копирование ссылок (wayland)
        pulseaudio    # pactl для аудиодорожек (работает с pipewire)
      ])}"
    ];

    postInstall = ''
      install -Dm644 vice.desktop $out/share/applications/vice.desktop
      install -Dm644 assets/vice.svg $out/share/icons/hicolor/scalable/apps/vice.svg
    '';

    doCheck = false;
  };
in
{
  home.packages = [ vice ];

  # Демон клипов: буфер всегда крутится в фоне, F9 - сохранить клип
  systemd.user.services.vice = {
    Unit = {
      Description = "Vice game clip recorder daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${vice}/bin/vice start --no-open-ui";
      Restart = "on-failure";
      RestartSec = 3;
      Environment = [ "PATH=/run/wrappers/bin:/run/current-system/sw/bin" ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
