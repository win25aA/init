# rofi: лаунчер и тема.
{ config, pkgs, ... }:

{
  imports = [
    ./scripts.nix # Вспомогательные команды этого приложения
  ];

  home.packages = with pkgs; [ rofi jq gammastep clipmenu pavucontrol ];

  xdg.configFile."rofi/config.rasi".text = ''
    /* rofi — лаунчер и меню. Цвета: matugen-colors.rasi от matugen */
    configuration {
        dpi: 96;
        modi: "drun";
        show-icons: true;
        icon-theme: "Papirus-Dark";
        display-drun: "";
        drun-display-format: "{name}";
        disable-history: false;
        max-history-size: 100;
        sort: false;
        hover-select: true;
        me-select-entry: "";
        me-accept-entry: "MousePrimary";
        kb-cancel: "Escape,Super+space";
    }

    @import "${config.xdg.configHome}/rofi/matugen-colors.rasi"

    * {
        font: "JetBrainsMono Nerd Font Propo Bold 10";
        background-color: transparent;
        text-color: @fg;
        margin: 0;
        padding: 0;
        spacing: 0;
    }

    window {
        location: center;
        width: 480px;
        border: 0;
        border-radius: 6px;
        background-color: @bg;
        padding: 12px;
    }

    mainbox {
        spacing: 10px;
        children: [ inputbar, message, listview ];
    }

    inputbar {
        background-color: @bg-alt;
        border-radius: 6px;
        padding: 8px 12px;
        spacing: 10px;
        children: [ prompt, entry ];
    }

    prompt { text-color: @accent; }

    entry {
        placeholder: "Поиск…";
        placeholder-color: @grey;
        cursor: text;
    }

    message {
        background-color: @bg-alt;
        border-radius: 6px;
        padding: 8px 12px;
    }

    textbox { text-color: @grey; }

    listview {
        lines: 8;
        columns: 1;
        dynamic: true;
        fixed-height: false;
        scrollbar: false;
        cycle: true;
        spacing: 4px;
    }

    element {
        padding: 7px 10px;
        border-radius: 6px;
        spacing: 10px;
    }

    element normal.normal, element alternate.normal { background-color: transparent; text-color: @fg; }
    element selected.normal { background-color: @bg-sel; text-color: @accent; }
    element normal.active, element alternate.active { background-color: transparent; text-color: @active; }
    element selected.active { background-color: @bg-sel; text-color: @active; }
    element normal.urgent, element alternate.urgent { background-color: transparent; text-color: @urgent; }
    element selected.urgent { background-color: @bg-sel; text-color: @urgent; }

    element-icon {
        size: 22px;
        vertical-align: 0.5;
    }

    element-text {
        vertical-align: 0.5;
        text-color: inherit;
    }
  '';
}
