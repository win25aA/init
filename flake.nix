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
# удалить для анстейбла
   hyprland.url = "github:hyprwm/Hyprland?ref=v0.55.4&submodules=1";
};

  outputs = inputs@{ self, nixpkgs, home-manager, spotx-nix, ... }: {
    nixosConfigurations.winarowk = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/winarowk
        home-manager.nixosModules.home-manager
      ];
    };
  };
}
