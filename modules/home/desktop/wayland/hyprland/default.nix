# Hyprland: Home Manager генерирует hyprland.lua и подключает Lua-модули.
# Пакет и портал по-прежнему устанавливает системный модуль NixOS.
{ config, lib, ... }:

{
  imports = [
    ./binds.nix # Подключение binds.lua через Home Manager
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    xwayland.enable = true;
    package = null;
    portalPackage = null;

    configType = "lua";

    # Сначала Home Manager регистрирует свои systemd/D-Bus hooks,
    # затем extraConfig загружает настройки с автозапуском приложений.
    extraLuaFiles.settings = {
      content = ./settings.lua;
      autoLoad = false;
    };

    extraLuaFiles.animations = {
      content = ./animations.lua;
      autoLoad = false;
    };

    extraConfig = ''
      -- Noctalia 5.x возвращает модуль: одного require недостаточно.
      -- Тема загружается до личных настроек, как прежний sourceFirst.
      -- Необязательная/повреждённая тема не должна отключать весь конфиг.
      local ok, err = pcall(function()
        local theme = require("noctalia")
        if type(theme) == "table" and type(theme.apply_theme) == "function" then
          theme.apply_theme()
        end
      end)
      if not ok then
        print("Noctalia theme: " .. tostring(err))
      end

      require("settings")
      require("animations")
    '';
  };

  # Noctalia перезаписывает этот файл при генерации цветов, поэтому он
  # намеренно НЕ является read-only симлинком Home Manager в /nix/store.
  # Существующие noctalia.lua и старый noctalia.conf не трогаем.
  home.activation.ensureNoctaliaLua = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    hypr_dir=${lib.escapeShellArg "${config.xdg.configHome}/hypr"}
    mkdir -p "$hypr_dir"
    if [ ! -e "$hypr_dir/noctalia.lua" ] && [ ! -L "$hypr_dir/noctalia.lua" ]; then
      cat > "$hypr_dir/noctalia.lua" <<'LUA'
    -- Noctalia заменит этот модуль при следующей генерации цветов.
    return { apply_theme = function() end }
    LUA
    fi
  '';
}
