# Программы системы. Поиск: `nf название`.
{ pkgs, ... }:

{
  # Программы с отдельными настройками
  programs.firefox.enable = true;

  programs.gpu-screen-recorder.enable = true;

  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  # Нужен Thunar: превью, корзина и монтирование
  services.gvfs.enable = true;

  programs.virt-manager.enable = true;
  virtualisation.libvirtd = {
    enable = true;
    qemu.swtpm.enable = true;
  };
  virtualisation.spiceUSBRedirection.enable = true;

  # Пакеты
  environment.systemPackages = with pkgs; [
    qbittorrent
    vesktop
    ayugram-desktop
    spotify-session # pkgs/spotify-session.nix
    vlc
    musikcube
    cava
    mpv
    loupe
    yt-dlp
    gpu-screen-recorder-gtk
    mpvpaper
    wine64
    winetricks
    protontricks
    bottles
    prismlauncher
    osu-lazer-bin
    git
    nodejs_22
    python3
    python3Packages.pip
    uv
    opencode-desktop
    thunar
    tumbler
    ffmpegthumbnailer
    (symlinkJoin {
      name = "peazip-themed"; paths = [ peazip ];
      nativeBuildInputs = [ makeWrapper ];
      postBuild = ''wrapProgram "$out/bin/peazip" --set QT_QPA_PLATFORMTHEME qt6ct'';
    })
    file-roller
    zip
    unzip
    gzip
    micro
    mousepad
    eza
    starship
    wget
    mtr
    hyfetch
    asciiquarium
    pavucontrol
    gparted
    gptfdisk
    ncdu
    btrfs-progs
    exfat
    exfatprogs
    ntfs3g
    dosfstools
    mtools
    libimobiledevice
    ifuse
    android-tools
    appimage-run
  ];
}
