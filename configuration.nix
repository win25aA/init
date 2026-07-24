
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
in



{
environment.systemPackages = with pkgs; [
  gpu-screen-recorder
  prismlauncher
  file-roller
  micro
  cava
    gparted
    exfat
    exfatprogs
    ntfs3g
    dosfstools
    mtools
    gptfdisk
    btrfs-progs
  inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
  xwayland-satellite # X11-приложения (Steam и т.д.) в niri
  android-tools
  pavucontrol
  matugen
  appimage-run
  thunar
  ncdu
  asciiquarium
  ayugram-desktop
  mousepad
  hyfetch 
  wireplumber         
  brightnessctl     
  playerctl
  git
  firefox
  adw-gtk3
  papirus-icon-theme
  osu-lazer-bin 
  wget
  vesktop
  inputs.zen-browser.packages."${pkgs.system}".default
  eza
  starship
  gzip
  zip
  unzip
  (import inputs.creamlinux-installer { inherit pkgs; })
  ] ++ [ simple-sddm-2-theme spotify-adblocked ];

programs.dconf.enable = true;
programs.amnezia-vpn.enable = true;
programs.steam.enable = true;
services.flatpak.enable = true;
services.usbmuxd.enable = true;
programs.nix-ld.enable = true;
boot.loader.grub.device = "/dev/sdc";
boot.loader.grub.enable = true;
boot.loader.grub.theme = ./grub-theme;
boot.loader.grub.useOSProber = true;
  services.xserver.enable = true;
services.gvfs.enable = true;

# Включение корректных прав (setuid) для pkexec
security.wrappers.pkexec = {
  setuid = true;
  owner = "root";
  group = "root";
  source = "${pkgs.polkit.bin}/bin/pkexec";
};

  boot.supportedFilesystems = [ "btrfs" ];
 security.polkit.enable = true;

hardware.graphics = {
  enable = true;
  enable32Bit = true; # Нужно для Steam и старых игр
};

environment.sessionVariables.NIXOS_OZONE_WL = "1";
boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
# Указываем системе использовать драйвер Nvidia
services.xserver.videoDrivers = [ "nvidia" ];

hardware.nvidia = {
open = false;  
modesetting.enable = true;
  powerManagement.enable = false;
  powerManagement.finegrained = false;
  
  nvidiaSettings = true;
  package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
};


home-manager = {
  useGlobalPkgs = true;
  useUserPackages = true;
  extraSpecialArgs = { inherit inputs; };

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
  };

qt = {
        enable = true;
        platformTheme.name = "gtk";
      };
    };
  };




programs.hyprland = {
  enable = true;
  xwayland.enable = true; # Нужен, чтобы старые X11-приложения запускались без проблем

};


programs.niri.enable = true;
programs.niri.package = pkgs.niri; # пакет из nixpkgs, а не сборка из niri-flake
niri-flake.cache.enable = false; # cachix не нужен для пакета из nixpkgs























  imports = [./hardware-configuration.nix ];


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

fileSystems."/mnt/games" = {
  device = "/dev/disk/by-uuid/3f80c736-41e1-4e16-a46e-716f4650aa8b";
  fsType = "ext4";
  options = [ "users" "nofail" "x-systemd.automount" "exec" ];
};


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

  services.xserver.xkb = {
    layout = "us,ru";
    options = "grp:alt_shift_toggle";    
    variant = "";
  };
  services.spice-vdagentd.enable = true;
  services.printing.enable = true;
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  users.users."winarowk" = {
    isNormalUser = true;
    description = "winarowk";
    extraGroups = [ "networkmanager" "wheel" "adbusers" ];
    packages = with pkgs; [
    ];
  };
  programs.firefox.enable = true;
  nixpkgs.config.allowUnfree = true;

  # gyre-fonts выключен намеренно: без кириллицы, ломает русский текст в GMod
  fonts.enableDefaultPackages = false;
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


fonts.fontconfig.defaultFonts = {
  sansSerif = [ "DejaVu Sans" "Liberation Sans" ];
  serif     = [ "DejaVu Serif" "Liberation Serif" ];
  monospace = [ "DejaVu Sans Mono" "Liberation Mono" ];
  emoji     = [ "Noto Color Emoji" ];
};

  system.stateVersion = "26.05"; 
  nix.settings.experimental-features = [ "nix-command" "flakes" ];  
}
