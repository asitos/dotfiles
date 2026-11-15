{
  description = "NixOS system with Serpantinum";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    serpantinum = {
      url = "github:ilyamiro/serpantinum";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, serpantinum, ... }@inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs serpantinum; };
      modules = [
        ./hardware-configuration.nix
        ./configuration.nix
        serpantinum.nixosModules.default
      ];
    };
  };
}
