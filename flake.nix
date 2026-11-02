{
  description = "Мой объединенный flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    spotx-nix = {
      url = "github:SpotX-Official/SpotX-Nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Тема Isabel для bspwm (темы rofi, picom, шрифты, обои, скрипты). Не flake, просто файлы.
    gh0stzk = {
      url = "github:gh0stzk/dotfiles";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, spotx-nix, ... }:
    let
      lib = nixpkgs.lib;

      # Каждая папка в hosts/ (кроме _template) — отдельный компьютер.
      hosts = lib.attrNames (lib.filterAttrs
        (name: type: type == "directory" && name != "_template")
        (builtins.readDir ./hosts));

      mkHost = name: lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/${name}
          home-manager.nixosModules.home-manager
          { networking.hostName = lib.mkDefault name; }
        ];
      };
    in
    {
      nixosConfigurations = lib.genAttrs hosts mkHost;
    };
}
