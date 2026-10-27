# Node.js: глобальные npm-пакеты в ~/.npm-global, ~/.local/bin в PATH.
{ ... }:

{
  home.sessionVariables = {
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
  };

  home.sessionPath = [
    "$HOME/.npm-global/bin"
    "$HOME/.local/bin"
  ];
}
