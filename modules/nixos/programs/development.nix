# Разработка.
{ pkgs, ... }:

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
