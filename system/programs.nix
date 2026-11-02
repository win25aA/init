# Все программы системы, по разделам.
{ lib, pkgs, ... }:

lib.mkMerge [
  # ════════════════════════════════════════════════════════════
  # Интернет: браузер, торренты и мессенджеры.
  {
    programs.firefox.enable = true;

    environment.systemPackages = with pkgs; [
      qbittorrent

      # Мессенджеры
      vesktop
      ayugram-desktop
    ];
  }

  # ════════════════════════════════════════════════════════════
  # Музыка, видео, картинки, запись экрана.
  {
    environment.systemPackages = with pkgs; [
      spotify-session      # pkgs/spotify-session.nix
      vlc
      musikcube
      cava
      mpv
      loupe
      yt-dlp
      gpu-screen-recorder-gtk
      mpvpaper
    ];
    programs.gpu-screen-recorder.enable = true;
  }

  # ════════════════════════════════════════════════════════════
  # Игры: Steam, Wine, лаунчеры.
  {
    programs.steam = {
      enable = true;
      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
    };

    environment.systemPackages = with pkgs; [
      # Wine / Proton
      wine64
      winetricks
      protontricks
      bottles

      # игры и лаунчеры
      prismlauncher
      osu-lazer-bin
    ];
  }

  # ════════════════════════════════════════════════════════════
  # Разработка.
  {
    environment.systemPackages = with pkgs; [
      git
      nodejs_22
      python3
      python3Packages.pip
      uv
      opencode-desktop
    ];
  }

  # ════════════════════════════════════════════════════════════
  # Файловый менеджер Thunar: превью, корзина и монтирование (gvfs).
  {
    services.gvfs.enable = true;

    environment.systemPackages = with pkgs; [
      thunar
      tumbler
      ffmpegthumbnailer
    ];
  }

  # ════════════════════════════════════════════════════════════
  # Повседневные утилиты: архивы, текстовые редакторы и команды терминала.
  {
    environment.systemPackages = with pkgs; [
      # Архивы
      peazip
      file-roller
      zip
      unzip
      gzip

      # Текстовые редакторы
      micro
      mousepad

      # Оболочка и консоль
      eza
      starship
      wget
      mtr
      hyfetch
      asciiquarium
    ];
  }

  # ════════════════════════════════════════════════════════════
  # Виртуальные машины: libvirt + virt-manager.
  {
    programs.virt-manager.enable = true;

    virtualisation.libvirtd = {
      enable = true;
      qemu.swtpm.enable = true;
    };
    virtualisation.spiceUSBRedirection.enable = true;
  }
]
