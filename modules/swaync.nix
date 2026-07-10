{ config, pkgs, inputs, ... }:

{
  # notify-send для тестов и скриптов
  home.packages = with pkgs; [ libnotify ];

  services.swaync = {
    enable = true;

    settings = {
      positionX = "right";
      positionY = "top";
      layer = "overlay";
      control-center-layer = "top";
      layer-shell = true;
      cssPriority = "user";

      timeout = 6;
      timeout-low = 4;
      timeout-critical = 0;

      notification-window-width = 380;
      notification-icon-size = 48;
      notification-body-image-height = 160;
      notification-body-image-width = 180;

      control-center-width = 400;
      control-center-margin-top = 6;
      control-center-margin-end = 10;

      hide-on-clear = true;
      hide-on-action = true;
      keyboard-shortcuts = true;

      widgets = [ "title" "dnd" "notifications" ];
      widget-config = {
        title = {
          text = "Уведомления";
          clear-all-button = true;
          button-text = "Очистить";
        };
        dnd = {
          text = "Не беспокоить";
        };
      };
    };

    style = ''
      @import "${config.home.homeDirectory}/.config/swaync/matugen-colors.css";

      * {
        font-family: sans-serif, "Symbols Nerd Font";
      }

      /* ---------- всплывающие уведомления ---------- */

      .notification-row {
        outline: none;
        margin: 0;
        padding: 0;
      }

      .notification-background {
        background: transparent;
        padding: 0;
      }

      .notification {
        background: alpha(@background, 0.85);
        border: 1px solid alpha(@primary, 0.5);
        border-radius: 14px;
        margin: 6px 10px;
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.35);
      }

      .notification.critical {
        border: 1px solid @error;
      }

      .notification-content {
        padding: 10px;
      }

      .summary {
        color: @text;
        font-size: 13px;
        font-weight: 800;
      }

      .time {
        color: @text_muted;
        font-size: 11px;
      }

      .body {
        color: @text_muted;
        font-size: 12px;
      }

      .image {
        border-radius: 10px;
        margin-right: 8px;
      }

      .close-button {
        background: @surface;
        color: @text;
        border-radius: 100%;
        margin: 6px;
        padding: 2px;
        box-shadow: none;
        border: none;
        transition: all 0.2s ease;
      }

      .close-button:hover {
        background: @error;
        color: @on_primary;
      }

      .notification-default-action {
        background: transparent;
        border: none;
        border-radius: 14px;
        color: @text;
      }

      .notification-action {
        background: @surface;
        border: none;
        border-radius: 10px;
        margin: 0 6px 8px 6px;
        color: @text;
        transition: all 0.2s ease;
      }

      .notification-action:hover {
        background: @primary;
        color: @on_primary;
      }

      /* прогресс-бар (громкость/яркость через notify-send -h int:value:N) */
      progressbar {
        border-radius: 100px;
        margin: 4px 0 2px 0;
      }

      progressbar trough {
        background: @surface_high;
        border-radius: 100px;
        min-height: 8px;
      }

      progressbar progress {
        background: @primary;
        border-radius: 100px;
        min-height: 8px;
      }

      /* ---------- центр уведомлений ---------- */

      .control-center {
        background: alpha(@background, 0.9);
        border: 1px solid alpha(@primary, 0.4);
        border-radius: 14px;
        margin: 6px 10px;
      }

      .control-center .notification {
        background: @surface;
        border: 1px solid alpha(@outline, 0.3);
        box-shadow: none;
      }

      .widget-title {
        color: @text;
        font-size: 14px;
        font-weight: 800;
        margin: 10px;
      }

      .widget-title > button {
        background: @surface;
        color: @text;
        border: none;
        border-radius: 10px;
        padding: 4px 12px;
        transition: all 0.2s ease;
      }

      .widget-title > button:hover {
        background: @primary;
        color: @on_primary;
      }

      .widget-dnd {
        color: @text;
        font-size: 12px;
        font-weight: 700;
        margin: 0 10px 10px 10px;
      }

      .widget-dnd > switch {
        background: @surface_high;
        border: none;
        border-radius: 100px;
      }

      .widget-dnd > switch:checked {
        background: @primary;
      }

      .widget-dnd > switch slider {
        background: @text;
        border-radius: 100px;
      }
    '';
  };
}
