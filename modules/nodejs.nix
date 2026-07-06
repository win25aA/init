{ config, pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    nodejs_22
  ];

  home.sessionVariables = {
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
  };

  home.sessionPath = [
    "$HOME/.npm-global/bin"
  ];
}
