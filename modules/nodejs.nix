{ config, pkgs, inputs, ... }:

{
  # Сами пакеты (nodejs_22, uv) — в environment.systemPackages
  # в configuration.nix, здесь только окружение для npm.

  # npm по умолчанию пытается писать глобальные пакеты в системную папку,
  # которая в NixOS read-only. Перенаправляем в домашнюю директорию.
  home.sessionVariables = {
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
  };

  home.sessionPath = [
    "$HOME/.npm-global/bin"
    "$HOME/.local/bin"
  ];
}
