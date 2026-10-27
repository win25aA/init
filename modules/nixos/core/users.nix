# Пользователи системы.
{ ... }:

{
  users.users."winarowk" = {
    isNormalUser = true;
    description = "winarowk";
    extraGroups = [ "networkmanager" "wheel" "adbusers" "libvirtd" ];
  };
}
