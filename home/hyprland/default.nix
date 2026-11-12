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
      nvidia = osConfig.my.gpu == "nvidia" && !osConfig.my.nvidia.prime.enable;

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
          -- Цвета генерируются matugen, но личные настройки ниже имеют приоритет.
          local ok, err = pcall(require, "hyprland.colors")
          if not ok then print("ii colors: " .. tostring(err)) end

          require("hardware")
          require("settings")
          require("animations")
          local overridesOk, overridesErr = pcall(require, "hyprland.shellOverrides.main")
          if not overridesOk then print("ii overrides: " .. tostring(overridesErr)) end
        '';
      };

      # Оба файла генерируются оболочкой и должны оставаться записываемыми.
      home.activation.ensureIiHyprFiles = config.lib.dag.entryAfter [ "writeBoundary" ] ''
        hypr_dir=${lib.escapeShellArg "${config.xdg.configHome}/hypr/hyprland"}
        mkdir -p "$hypr_dir"
        [ -e "$hypr_dir/colors.lua" ] || printf '%s\n' '-- matugen создаст цвета' > "$hypr_dir/colors.lua"
      '';

    }
  )

  # ════════════════════════════════════════════════════════════
  # Горячие клавиши написаны на Lua; файл устанавливает Home Manager.
  {
    wayland.windowManager.hyprland.extraLuaFiles.binds = ./binds.lua;
  }
]
