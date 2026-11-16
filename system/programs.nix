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

  # Нужен Thunar: превью, корзина, монтирование.
  services.gvfs.enable = true;
  
  systemd.user.services.gvfs-heal = {
    description = "Heal gvfs: поднять демоны после сбоя gvfsd-fuse";
    wantedBy = [ "default.target" ];
    path = with pkgs; [ coreutils ];
    serviceConfig.Type = "oneshot";
    serviceConfig.ExecStart = pkgs.writeShellScript "gvfs-heal" ''
      sleep 10
      ls "$HOME/.gvfs" >/dev/null 2>&1 \
        && ls "/run/user/$(id -u)/gvfs" >/dev/null 2>&1 && exit 0
      /run/wrappers/bin/fusermount3 -u "$HOME/.gvfs" 2>/dev/null || true
      /run/wrappers/bin/fusermount3 -u "/run/user/$(id -u)/gvfs" \
        2>/dev/null || true
      systemctl --user restart gvfs-daemon.service \
        gvfs-udisks2-volume-monitor.service gvfs-mtp-volume-monitor.service \
        gvfs-gphoto2-volume-monitor.service
    '';
  };

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
    codex
    musikcube
    amberol
    pinta
    gimp
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
    opencode
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
