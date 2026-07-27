
{ config, pkgs, inputs, ... }:

let
  spotify-adblock = pkgs.rustPlatform.buildRustPackage {
    pname = "spotify-adblock";
    version = "unstable-2026-06-07";
    src = pkgs.fetchFromGitHub {
      owner = "abba23";
      repo = "spotify-adblock";
      rev = "9aeadd3cfd4d50212059720c09f662f149942fec";
      hash = "sha256-3X7vScKmnb65wJ4xWAT2AeyAMPTGzKZCFA549zm9gLc=";
    };
    cargoHash = "sha256-gxGetdqaoJa/ZF1VnW6UXJyJfLBGZxZnyKpT/Qk/8Og=";

    patchPhase = ''
      substituteInPlace src/config.rs \
        --replace-fail 'const GLOBAL_CONFIG_DIR: &str = "/etc";' \
                  "const GLOBAL_CONFIG_DIR: &str = \"$out/etc\";"
    '';

    buildPhase = "make";

    installPhase = ''
      mkdir -p $out/etc/spotify-adblock
      install -D --mode=644 config.toml $out/etc/spotify-adblock
      mkdir -p $out/lib
      install -D --mode=644 --strip target/release/libspotifyadblock.so $out/lib
    '';
  };

  spotify-adblocked = pkgs.spotify.overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.zip pkgs.unzip ];
    postInstall = (old.postInstall or "") + ''
      ln -s ${spotify-adblock}/lib/libspotifyadblock.so $libdir
      wrapProgram $out/bin/spotify \
        --set LD_PRELOAD "${spotify-adblock}/lib/libspotifyadblock.so"

      ${pkgs.unzip}/bin/unzip -p $out/share/spotify/Apps/xpui.spa xpui-snapshot.js | sed 's/adsEnabled:!0/adsEnabled:false/' > $out/share/spotify/Apps/xpui-snapshot.js
      ${pkgs.zip}/bin/zip --junk-paths --update $out/share/spotify/Apps/xpui.spa $out/share/spotify/Apps/xpui-snapshot.js
      rm $out/share/spotify/Apps/xpui-snapshot.js
    '';
  });

  simple-sddm-2-theme = pkgs.runCommand "simple-sddm-2-theme" {} ''
    mkdir -p $out/share/sddm/themes/simple-sddm-2
    cp -r ${./simple-sddm-2}/* $out/share/sddm/themes/simple-sddm-2/
  '';

  noctalia-nvml = pkgs.symlinkJoin {
    name = "noctalia-nvml";
    paths = [ inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for bin in $out/bin/*; do
        wrapProgram "$bin" --suffix LD_LIBRARY_PATH : /run/opengl-driver/lib
      done
    '';
  };
in
{
  # ======================================================================
  # ПАКЕТЫ
  # ======================================================================
  environment.systemPackages = with pkgs; [
    # --- Интернет и общение ---
    inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".default
    vesktop          
    ayugram-desktop 
    qbittorrent
    # --- Игры ---
    prismlauncher   
    osu-lazer-bin    
    gpu-screen-recorder
    (import inputs.creamlinux-installer { inherit pkgs; })
    # --- Музыка и звук ---
    spotify-adblocked
    pavucontrol
    wireplumber
    playerctl
    cava
    # --- Просмотр медиа ---
    mpv                
    loupe              
    musikcube
    tumbler            
    ffmpegthumbnailer  
    amberol
    # --- Файлы и диски ---
    thunar
    file-roller
    gparted
    ncdu
    exfat
    exfatprogs
    ntfs3g
    dosfstools
    mtools
    gptfdisk
    btrfs-progs
    # --- Рабочий стол ---
    noctalia-nvml
    xwayland-satellite
    matugen
    brightnessctl
    adw-gtk3
    papirus-icon-theme
    simple-sddm-2-theme
    # --- Разработка ---
    git
    nodejs_22
    uv
    android-tools
    # --- Редакторы ---
    micro
    mousepad
    # --- Терминал и CLI ---
    eza
    starship
    hyfetch
    asciiquarium
    nvtopPackages.nvidia
    wget
    gzip
    zip
    unzip
    appimage-run
    opencode
  ];

  # ======================================================================
  # ПРОГРАММЫ
  # ======================================================================
  programs.firefox.enable = true;
  programs.steam.enable = true;
  programs.amnezia-vpn.enable = true;
  programs.dconf.enable = true;
  programs.nix-ld.enable = true;
  programs.ns-usbloader.enable = true;
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # ======================================================================
  # ВИРТУАЛКА
  # ======================================================================
  programs.virt-manager.enable = true;
  virtualisation.libvirtd = {
    enable = true;
    qemu.swtpm.enable = true;
  };
  virtualisation.spiceUSBRedirection.enable = true;

  # ======================================================================
  # СЕРВИСЫ
  # ======================================================================
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "simple-sddm-2";
    extraPackages = with pkgs.kdePackages; [
      qtmultimedia
      qtsvg
      qtvirtualkeyboard
    ];
  };

  services.xserver.enable = true;
  services.xserver.xkb = {
    layout = "us,ru";
    options = "grp:alt_shift_toggle";
    variant = "";
  };

  # pipewire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services.flatpak.enable = true;
  services.usbmuxd.enable = true;
  services.gvfs.enable = true;
  services.printing.enable = true;

  # ======================================================================
  # ЗАГРУЗКА
  # ======================================================================
  boot.loader.grub.device = "/dev/disk/by-id/ata-Apacer_AS340_480GB_AFLJ1451210075";
  boot.loader.grub.enable = true;
  boot.loader.grub.theme = ./grub-theme;
  boot.loader.grub.useOSProber = true;

  boot.supportedFilesystems = [ "btrfs" ];

  # ======================================================================
  # ВИДЕОКАРТА
  # ======================================================================
  boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    open = false;
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # ======================================================================
  # СЕТЬ, ЛОКАЛЬ, ВРЕМЯ
  # ======================================================================
  networking.hostName = "winarowk";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Moscow";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ru_RU.UTF-8";
    LC_IDENTIFICATION = "ru_RU.UTF-8";
    LC_MEASUREMENT = "ru_RU.UTF-8";
    LC_MONETARY = "ru_RU.UTF-8";
    LC_NAME = "ru_RU.UTF-8";
    LC_NUMERIC = "ru_RU.UTF-8";
    LC_PAPER = "ru_RU.UTF-8";
    LC_TELEPHONE = "ru_RU.UTF-8";
    LC_TIME = "ru_RU.UTF-8";
  };

  # ======================================================================
  # ДИСКИ
  # ======================================================================
  fileSystems."/mnt/games" = {
    device = "/dev/disk/by-uuid/3f80c736-41e1-4e16-a46e-716f4650aa8b";
    fsType = "ext4";
    options = [ "users" "nofail" "x-systemd.automount" "exec" ];
  };

  # ======================================================================
  # БЕЗОПАСНОСТЬ
  # ======================================================================
  security.polkit.enable = true;

  # Включение корректных прав (setuid) для pkexec
  security.wrappers.pkexec = {
    setuid = true;
    owner = "root";
    group = "root";
    source = "${pkgs.polkit.bin}/bin/pkexec";
  };

  # ======================================================================
  # ПОЛЬЗОВАТЕЛЬ И HOME MANAGER
  # ======================================================================
  users.users."winarowk" = {
    isNormalUser = true;
    description = "winarowk";
    extraGroups = [ "networkmanager" "wheel" "adbusers" "libvirtd" ];
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    backupFileExtension = "hm-backup";

    users.winarowk = { pkgs, ... }: {
      imports = [ ./home.nix ];

      home.stateVersion = "26.11";

      gtk = {
        enable = true;
        theme = {
          name = "adw-gtk3-dark";
          package = pkgs.adw-gtk3;
        };
        iconTheme = {
          name = "Papirus";
          package = pkgs.papirus-icon-theme;
        };
        # Динамические цвета из matugen (файлы генерируются при смене обоев)
        gtk3.extraCss = ''@import url("matugen-colors.css");'';
        gtk4.extraCss = ''@import url("matugen-colors.css");'';
      };

      qt = {
        enable = true;
        platformTheme.name = "gtk3";
      };
    };
  };

  # ======================================================================
  # ШРИФТЫ
  # ======================================================================
  fonts.enableDefaultPackages = false;

  fonts.fontconfig.defaultFonts = {
    sansSerif = [ "DejaVu Sans" "Liberation Sans" ];
    serif     = [ "DejaVu Serif" "Liberation Serif" ];
    monospace = [ "DejaVu Sans Mono" "Liberation Mono" ];
    emoji     = [ "Noto Color Emoji" ];
  };

  fonts.packages = with pkgs; [
    dejavu_fonts
    freefont_ttf
    liberation_ttf
    unifont
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    corefonts
  ];

  # ======================================================================
  # NIX И СИСТЕМА
  # ======================================================================
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Автоочистка, оптимизация
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.settings.auto-optimise-store = true;

  system.stateVersion = "26.05";
}
