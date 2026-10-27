# Внешние устройства: iPhone, Android, Nintendo Switch, MediaTek.
{ pkgs, ... }:

{
  # iPhone
  services.usbmuxd.enable = true;

  # Nintendo Switch
  programs.ns-usbloader.enable = true;

  # MediaTek (прошивка/сервисный режим) — доступ без root
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="0e8d", MODE="0666", GROUP="users"
  '';

  environment.systemPackages = with pkgs; [
    libimobiledevice
    ifuse
    android-tools
  ];
}
