
{ config, pkgs, inputs, ... }:

let
  # Получаем пакеты spicetify из inputs
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};


  
  simple-sddm-2-theme = pkgs.runCommand "simple-sddm-2-theme" {} ''
    mkdir -p $out/share/sddm/themes/simple-sddm-2
    cp -r ${./simple-sddm-2}/* $out/share/sddm/themes/simple-sddm-2/

  '';
in



{
environment.systemPackages = with pkgs; [
  android-tools
  matugen
  appimage-run
  thunar
  ncdu
  asciiquarium
  ayugram-desktop
  nodejs_22
  uv
  hyfetch 
  wireplumber         
  brightnessctl     
  playerctl
  git
  hyprland
  firefox
  kitty
  fish 
  fastfetch  
  adw-gtk3
  papirus-icon-theme
  amnezia-vpn-bin
  osu-lazer-bin 
  wget
  vesktop
  neovim
  spotify
  btop
  grim
  slurp
  wl-clipboard
  eza
  starship
  gzip
  zip
  unzip
  (import inputs.creamlinux-installer { inherit pkgs; })
  inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
  ] ++ [ simple-sddm-2-theme ];

programs.dconf.enable = true;
programs.amnezia-vpn.enable = true;
programs.steam.enable = true;
services.flatpak.enable = true;
services.usbmuxd.enable = true;
programs.nix-ld.enable = true;
boot.loader.grub.device = "/dev/sdb";
boot.loader.grub.enable = true;
boot.loader.grub.theme = ./grub-theme;
boot.loader.grub.useOSProber = true;
  services.xserver.enable = true;
services.gvfs.enable = true;

programs.spicetify = {
    enable = true;
    theme = spicePkgs.themes.comfy;
    colorScheme = "Mono";
    # Убраны запятые из списка
enabledExtensions = with spicePkgs.extensions; [ adblock shuffle ];
  };



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
  system.stateVersion = "26.05"; 
  nix.settings.experimental-features = [ "nix-command" "flakes" ];  
}
