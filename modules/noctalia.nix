{ config, ... }:

let
  repo = "/etc/nixos";
  link = path: config.lib.file.mkOutOfStoreSymlink "${repo}/${path}";
in
{
  xdg.stateFile."noctalia/settings.toml".source = link "modules/noctalia/settings.toml";

  xdg.configFile."noctalia/config.toml".source = link "modules/noctalia/config.toml";
}
