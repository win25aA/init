{ config, pkgs, inputs, ... }:

{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    font = "sans-serif Bold 12";
    location = "center";
    terminal = "${pkgs.kitty}/bin/kitty";
    extraConfig = {
      modi = "drun,run";
      show-icons = true;
      drun-display-format = "{name}";
    };
    theme = "${config.xdg.configHome}/rofi/theme.rasi";
  };

  xdg.configFile."rofi/theme.rasi".text = ''
    @import "~/.config/rofi/matugen-colors.rasi"

    * {
        background-color: transparent;
        text-color: @text;
    }

    window {
        transparency: "real";
        background-color: @background-trans;
        border: 2px;
        border-color: @primary;
        border-radius: 16px;
        width: 460px;
        padding: 14px;
    }

    mainbox {
        spacing: 12px;
        children: [ inputbar, listview ];
    }

    inputbar {
        background-color: @surface;
        border-radius: 12px;
        padding: 10px 14px;
        children: [ entry ];
    }

    entry {
        placeholder: "Поиск...";
        placeholder-color: @text-muted;
        cursor: text;
    }

    listview {
        lines: 6;
        columns: 1;
        spacing: 6px;
        scrollbar: false;
        fixed-height: false;
    }

    element {
        border-radius: 10px;
        padding: 8px 12px;
        spacing: 12px;
    }

    element normal.active,
    element alternate.active {
        text-color: @primary;
    }

    element normal.urgent,
    element alternate.urgent {
        text-color: @error;
    }

    element selected.normal,
    element selected.active,
    element selected.urgent {
        background-color: @primary;
        text-color: @on-primary;
    }

    element-icon {
        size: 26px;
    }

    element-text {
        text-color: inherit;
        vertical-align: 0.5;
        highlight: bold;
    }
  '';
}
