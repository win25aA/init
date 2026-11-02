# Hyprland: подключение Lua-файлов, мониторы и NVIDIA из hosts/<имя-пк>.
# Сами настройки: settings.lua, сочетания клавиш: binds.lua, анимации: animations.lua.
{ config, lib, osConfig, ... }:

lib.mkMerge [
  # ════════════════════════════════════════════════════════════
  # Hyprland: Home Manager генерирует hyprland.lua и подключает Lua-модули.
  # Пакет и портал по-прежнему устанавливает системный модуль NixOS.
  (
    let
      monitors = osConfig.my.monitors;
      nvidia = osConfig.my.gpu == "nvidia";

      monitorLua = m: ''
        hl.monitor({
            output = "${m.name}",
            mode = "${m.mode}",
            position = "${m.position}",
            scale = "${m.scale}",
        })
      '';

      workspaceLua = m: lib.concatMapStrings (ws: ''
        hl.workspace_rule({ workspace = "${toString ws}", monitor = "${m.name}" })
      '') m.workspaces;

      # Настройки, зависящие от железа (берутся из hosts/<имя-пк>).
      hardwareLua = ''
        -- Сгенерировано из my.monitors и my.gpu. Правится в hosts/<имя-пк>.

        -- Запасное правило: любой монитор без своей настройки
        -- включается в родном разрешении и ставится автоматически.
        hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "1" })

      '' + lib.concatMapStrings monitorLua monitors
        + lib.concatMapStrings workspaceLua monitors
        + lib.optionalString nvidia ''

        -- NVIDIA
        hl.env("LIBVA_DRIVER_NAME", "nvidia")
        hl.env("GBM_BACKEND", "nvidia-drm")
        hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
        hl.env("NVD_BACKEND", "direct")
        hl.env("WLR_NO_HARDWARE_CURSORS", "1")
      '';
    in
    {
      wayland.windowManager.hyprland = {
        enable = true;
        systemd.enable = true;
        xwayland.enable = true;
        package = null;
        portalPackage = null;

        configType = "lua";

        # Сначала Home Manager регистрирует свои systemd/D-Bus hooks,
        # затем extraConfig загружает настройки с автозапуском приложений.
        extraLuaFiles.hardware = {
          content = hardwareLua;
          autoLoad = false;
        };

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

          require("hardware")
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
  )

  # ════════════════════════════════════════════════════════════
  # Горячие клавиши написаны на Lua; файл устанавливает Home Manager.
  {
    wayland.windowManager.hyprland.extraLuaFiles.binds = ./binds.lua;
  }
]
