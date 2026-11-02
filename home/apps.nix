# Настройки приложений и разработки.
{ lib, ... }:

lib.mkMerge [
  # ════════════════════════════════════════════════════════════
  # Настройки приложений: цвета видеоплеера mpv от Matugen.
  {
    xdg.configFile."mpv/mpv.conf".text = ''
      include=~~/matugen-colors.conf
    '';
  }

  # ════════════════════════════════════════════════════════════
  # Node.js: глобальные npm-пакеты в ~/.npm-global, ~/.local/bin в PATH.
  {
    home.sessionVariables = {
      NPM_CONFIG_PREFIX = "$HOME/.npm-global";
    };

    home.sessionPath = [
      "$HOME/.npm-global/bin"
      "$HOME/.local/bin"
    ];
  }
]
