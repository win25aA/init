 { 
  description = "Мой объединенный flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    creamlinux-installer = {
     type = "github";
     owner = "novattz";
     repo = "creamlinux-installer";
     flake = false;
     };


    
    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs"; 
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  }; 

  outputs = inputs@{ self, nixpkgs, noctalia, home-manager, spicetify-nix, ... }: {
    nixosConfigurations.winarowk = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hardware-configuration.nix
        ./configuration.nix
        home-manager.nixosModules.home-manager
        spicetify-nix.nixosModules.default
      ];
    };
  };
}
