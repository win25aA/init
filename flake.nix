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

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  }; 

  outputs = inputs@{ self, nixpkgs, home-manager, ... }: {
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
