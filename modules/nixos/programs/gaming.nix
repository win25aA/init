# Игры: Steam, Wine, лаунчеры.
{ pkgs, ... }:

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
    creamlinux-installer   # pkgs/default.nix
  ];
}
