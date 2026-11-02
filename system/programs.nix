# Все программы системы. Сортировать ничего не нужно.
# Найти программу: `nf название`.
{ pkgs, ... }:

{
  # ════════════════════════════════════════════════════════════
  # Программы через переключатель (enable = true), со своими настройками.
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

  # ════════════════════════════════════════════════════════════
  # Обычные программы: просто допиши строку в конец списка.
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
    peazip
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
