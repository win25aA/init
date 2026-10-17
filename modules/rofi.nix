{ config, pkgs, lib, ... }:
let
  nightlight = pkgs.writeShellScriptBin "bspwm-nightlight" ''
    set -e
    flag="$XDG_RUNTIME_DIR/bspwm-nightlight"
    if [ -e "$flag" ]; then
      ${pkgs.redshift}/bin/redshift -x
      ${pkgs.coreutils}/bin/rm -f "$flag"
      ${pkgs.libnotify}/bin/notify-send 'Ночной свет' 'Выключен'
    else
      ${pkgs.redshift}/bin/redshift -P -O 4500
      ${pkgs.coreutils}/bin/touch "$flag"
      ${pkgs.libnotify}/bin/notify-send 'Ночной свет' '4500 K'
    fi
  '';
  cleanup = pkgs.writeShellScript "bspwm-nightlight-cleanup" ''
    flag="$XDG_RUNTIME_DIR/bspwm-nightlight"
    [ ! -e "$flag" ] || ${pkgs.redshift}/bin/redshift -x
    ${pkgs.coreutils}/bin/rm -f "$flag"
  '';
  menu = pkgs.writeShellScriptBin "desktop-menu" ''
    export PATH=${lib.makeBinPath [ pkgs.rofi pkgs.bspwm pkgs.coreutils pkgs.procps pkgs.systemd pkgs.gcal pkgs.pavucontrol pkgs.networkmanagerapplet pkgs.blueman ]}:${config.home.profileDirectory}/bin:/run/current-system/sw/bin:$PATH
    choose() { rofi -dmenu -i -no-custom -p "$1"; }
    confirm() {
      local answer
      answer=$(printf 'Отмена\nДа\n' | choose "$1") || return 1
      [ "$answer" = Да ]
    }
    case "$1" in
      launcher) exec rofi -show drun ;;
      calendar) rofi -e "$(gcal)" ;;
      usercard) rofi -e "$(id -un) · NixOS
    $(uname -r)
    $(uptime -p)" ;;
      exit) confirm 'Выйти из bspwm?' && bspc quit ;;
      session)
        choice=$(printf '%s\n' 'Блокировка' 'Сон' 'Выйти из bspwm' 'Перезагрузка' 'Выключение' | choose 'Сессия') || exit 0
        case "$choice" in
          Блокировка) bspwm-lock ;;
          Сон) bspwm-lock && systemctl suspend ;;
          'Выйти из bspwm') confirm 'Выйти?' && bspc quit ;;
          Перезагрузка) confirm 'Перезагрузка?' && systemctl reboot ;;
          Выключение) confirm 'Выключить?' && systemctl poweroff ;;
        esac
        ;;
      control)
        choice=$(printf '%s\n' 'Громкость и устройства' 'Сеть' 'Bluetooth' 'Обои и Matugen' 'Тема панели' 'Буфер обмена' 'Уведомления' 'Ночной свет' 'Скриншот области' 'Проверить nixpkgs' 'Сессия' | choose 'Управление') || exit 0
        case "$choice" in
          'Громкость и устройства') pavucontrol ;;
          Сеть) nm-connection-editor ;;
          Bluetooth) blueman-manager ;;
          'Обои и Matugen') choose-wallpaper ;;
          'Тема панели') polybar-theme ;;
          'Буфер обмена') bspwm-clipboard ;;
          Уведомления) bspwm-notifications ;;
          'Ночной свет') bspwm-nightlight ;;
          'Скриншот области') bspwm-screenshot region ;;
          'Проверить nixpkgs') bspwm-updates check ;;
          Сессия) desktop-menu session ;;
        esac
        ;;
    esac
  '';
in
{
  home.packages = [ pkgs.rofi menu nightlight ];
  xdg.configFile."rofi/config.rasi".text = ''
    configuration {
      modi: "drun,run";
      show-icons: true;
      font: "Maple Mono NF 11";
      display-drun: "Приложения";
      display-run: "Команда";
    }
    @theme "${config.xdg.configHome}/rofi/desktop.rasi"
  '';
  xdg.configFile."rofi/desktop.rasi".text = ''
    @import "${config.home.homeDirectory}/.local/state/bspwm/rofi-colors.rasi"
    * { background-color: transparent; text-color: @foreground; border-color: @outline; spacing: 8px; }
    window { width: 640px; background-color: @background; border: 2px; border-radius: 10px; padding: 16px; }
    mainbox { children: [ inputbar, message, listview ]; }
    inputbar { children: [ prompt, entry ]; padding: 8px; }
    prompt { padding: 0px 12px 0px 0px; }
    entry { placeholder: "Поиск…"; expand: true; }
    listview { lines: 10; columns: 1; fixed-height: false; }
    element { padding: 8px; spacing: 10px; border-radius: 6px; }
    element selected.normal { background-color: @selected; text-color: @on-selected; }
    element-icon { size: 28px; background-color: transparent; }
    element-text { background-color: transparent; text-color: inherit; }
    prompt { text-color: @selected; }
    message { padding: 8px; }
  '';
  systemd.user.services.bspwm-nightlight-cleanup = {
    Unit.PartOf = [ "bspwm-session.target" ];
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.coreutils}/bin/rm -f %t/bspwm-nightlight";
      ExecStop = toString cleanup;
    };
    Install.WantedBy = [ "bspwm-session.target" ];
  };
}
