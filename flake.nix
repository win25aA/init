 { 
  description = "Мой объединенный flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

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

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Исходники Vice (game clip recorder), пакуется в modules/vice.nix
    vice-src = {
      url = "github:eklonofficial/Vice/v1.3.4";
      flake = false;
    };
  }; 

  outputs = inputs@{ self, nixpkgs, home-manager, spicetify-nix, ... }: {
    nixosConfigurations.winarowk = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hardware-configuration.nix
        ./configuration.nix
        home-manager.nixosModules.home-manager
        spicetify-nix.nixosModules.default
        inputs.niri.nixosModules.niri
      ];
    };
  };
}
