
{ config, pkgs, inputs, ... }:

let

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

  soundcloud-desktop = pkgs.appimageTools.wrapType2 {
    pname = "soundcloud-desktop";
    version = "8.4.13";
    src = pkgs.fetchurl {
      url = "https://github.com/zxcloli666/SoundCloud-Desktop-EN/releases/download/8.4.13/soundcloud-desktop_8.4.13_amd64.AppImage";
      hash = "sha256-yM5BD/VYkhEHBD3tkvC7xbrsUup+olaD5Q8tuOjcKEc=";
    };
  };
in
{
  # pkgs
  environment.systemPackages = with pkgs; [
    inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".default
    vesktop     
    bottles
    wine64
    gpu-screen-recorder-gtk
    protontricks
    winetricks     
    ayugram-desktop 
    qbittorrent
    prismlauncher   
    osu-lazer-bin    
    gpu-screen-recorder
    (import inputs.creamlinux-installer { inherit pkgs; })
    pkgs.spotify-spotx
    pavucontrol
    wireplumber
    playerctl
    cava
    mpv                
    loupe              
    musikcube
    peazip
    tumbler            
    ffmpegthumbnailer  
    amberol
    mtr
    thunar
    file-roller
    gparted
    ncdu
    exfat
    exfatprogs
    ntfs3g
    dosfstools
    opencode-desktop
    mtools
    gptfdisk
    btrfs-progs
    noctalia-nvml
    xwayland-satellite
    matugen
    brightnessctl
    adw-gtk3
    papirus-icon-theme
    simple-sddm-2-theme
    git
    nodejs_22
    uv
    android-tools
    micro
    mousepad
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
    libimobiledevice
    ifuse
  ] ++ [ soundcloud-desktop ];

  # хуйня которую надо удалить для анстейбла, еще в hyprland nix flake nix
nix.settings = {
  substituters = [ "https://hyprland.cachix.org" ];
  trusted-public-keys = [
    "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
  ];
};
  # programs.
  programs.firefox.enable = true;
programs.steam = {
  enable = true;
  extraCompatPackages = with pkgs; [
    proton-ge-bin
  ];
};
  programs.amnezia-vpn.enable = true;
  programs.dconf.enable = true;
  programs.nix-ld.enable = true;
  programs.ns-usbloader.enable = true;
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    # удалить для анстейбла
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  programs.virt-manager.enable = true;
  virtualisation.libvirtd = {
    enable = true;
    qemu.swtpm.enable = true;
  };
  virtualisation.spiceUSBRedirection.enable = true;

  # сервисы
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

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;


  services.zapret = {
    enable = true;
    params = [
      # профиль 1 — голосовые порты Discord (UDP, без имени домена)
      "--filter-udp=50000-50100"
      "--dpi-desync=fake"
      "--dpi-desync-any-protocol"
      "--dpi-desync-repeats=6"
      "--new"
      # профиль 2 — обычные сайты (TCP), твоя рабочая стратегия
      "--filter-tcp=443"
      "--dpi-desync=fakedsplit"
      "--dpi-desync-fooling=ts"
      "--dpi-desync-split-pos=1"
    ];
    httpSupport = true;
    udpSupport = true;
    udpPorts = [ "50000:50100" ];
    configureFirewall = true;
    whitelist = [
      "youtube.com" "googlevideo.com" "ytimg.com" "ggpht.com" "youtu.be"
      "discord.com" "discordapp.com" "discord.gg" "discordapp.net"
      "instagram.com" "cdninstagram.com" "fbcdn.net"
      "rutracker.org"
    ];
  };
  
  services.flatpak.enable = true;
  services.usbmuxd.enable = true;
  services.gvfs.enable = true;
  services.printing.enable = true; 
    networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];
    services.resolved = {
      enable = true;
      dnsovertls = "true";
    };  
  # GRUB

  boot.loader.grub.device = "/dev/disk/by-id/ata-Apacer_AS340_480GB_AFLJ1451210075";
  boot.loader.grub.enable = true;
  boot.loader.grub.theme = ./grub-theme;
  boot.loader.grub.useOSProber = true;

  boot.supportedFilesystems = [ "btrfs" ];

  # nvidia

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

  # локали и инет
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

  # ДИСКИ
  fileSystems."/mnt/games" = {
    device = "/dev/disk/by-uuid/3f80c736-41e1-4e16-a46e-716f4650aa8b";
    fsType = "ext4";
    options = [ "users" "nofail" "x-systemd.automount" "exec" ];
  };

  security.polkit.enable = true;

  # Pkexec
  
  security.wrappers.pkexec = {
    setuid = true;
    owner = "root";
    group = "root";
    source = "${pkgs.polkit.bin}/bin/pkexec";
  };

  # юзеры и home manager

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

        gtk3.extraCss = ''@import url("matugen-colors.css");'';
        gtk4.extraCss = ''@import url("matugen-colors.css");'';
      };

      qt = {
        enable = true;
        platformTheme.name = "gtk3";
      };
    };
  };

  # ШРИФТЫ
  
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
    nerd-fonts.jetbrains-mono
    liberation_ttf
    unifont
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    corefonts
  ];

  # bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true; 
  

 
  # система никса

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [ inputs.spotx-nix.overlays.default ];

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
