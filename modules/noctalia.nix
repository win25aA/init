{ config, ... }:

let
  # Путь к этому репозиторию на живой системе.
  # Симлинки ведут в рабочее дерево, поэтому правки попадают прямо в git.
  repo = "/etc/nixos";
  link = path: config.lib.file.mkOutOfStoreSymlink "${repo}/${path}";
in
{
  # GUI noctalia сохраняет все свои изменения (обои, плагины, бары, тему)
  # в state-файл settings.toml. Noctalia умеет писать сквозь симлинк,
  # так что правки из GUI попадают в репозиторий и коммитятся через nrs.
  xdg.stateFile."noctalia/settings.toml".source = link "modules/noctalia/settings.toml";

  # Ручной декларативный конфиг (hot-reload через inotify).
  # Настройки отсюда — база, поверх неё накладывается settings.toml из GUI.
  xdg.configFile."noctalia/config.toml".source = link "modules/noctalia/config.toml";
}
