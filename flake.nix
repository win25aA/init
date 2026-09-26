 { 
  description = "Мой объединенный flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    spotx-nix = {
      url = "github:SpotX-Official/SpotX-Nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs"; # this line is optional, prevents downloading two versions of nixpkgs but disables cache
};
    creamlinux-installer = {
     type = "github";
     owner = "novattz";
     repo = "creamlinux-installer";
     flake = false;
     };

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs"; 
    };
# удалить для анстейбла
   hyprland.url = "github:hyprwm/Hyprland?ref=v0.55.4&submodules=1";

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  }; 

  outputs = inputs@{ self, nixpkgs, home-manager, spotx-nix, ... }: {
    nixosConfigurations.winarowk = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hardware-configuration.nix
        ./configuration.nix
        home-manager.nixosModules.home-manager
        inputs.niri.nixosModules.niri
      ];
    };
  };
}
