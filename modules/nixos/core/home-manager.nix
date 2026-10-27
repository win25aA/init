# Home Manager: подключаем пользовательские модули из modules/home.
{ inputs, ... }:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    backupFileExtension = "hm-backup";

    users.winarowk = import ../../home;
  };
}
