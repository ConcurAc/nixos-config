{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    retrom = {
      url = "github:JMBeresford/retrom/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-citizen = {
      url = "github:LovingMelody/nix-citizen";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      sops-nix,
      disko,
      stylix,
      ...
    }:
    let
      users = import ./users;
      specialArgs = {
        inherit inputs;
        modules = import ./modules;
        assets = import ./assets;
      };
    in
    {
      nixosConfigurations = {
        effigy = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          modules = [
            sops-nix.nixosModules.sops
            disko.nixosModules.disko
            stylix.nixosModules.stylix

            ./hosts/effigy

            users.connor
          ];
        };

        opus = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          modules = [
            sops-nix.nixosModules.sops
            disko.nixosModules.disko
            stylix.nixosModules.stylix

            ./hosts/opus

            users.connor
            users.liam
          ];
        };

        cadence = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          modules = [
            sops-nix.nixosModules.sops
            disko.nixosModules.disko
            stylix.nixosModules.stylix

            ./hosts/cadence

            users.connor
          ];
        };

        insomnia = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          modules = [
            sops-nix.nixosModules.sops
            disko.nixosModules.disko

            ./hosts/insomnia

            users.connor
          ];
        };
      };
    };
}
