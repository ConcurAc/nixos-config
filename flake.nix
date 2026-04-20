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
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
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
  };

  outputs =
    inputs@{
      nixpkgs,
      sops-nix,
      disko,
      stylix,
      nixvim,
      nix-minecraft,
      retrom,
      ...
    }:
    let
      resources = import ./resources;
    in
    {
      nixosConfigurations = {
        effigy = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs resources; };
          modules = [
            disko.nixosModules.disko
            sops-nix.nixosModules.sops

            stylix.nixosModules.stylix
            nixvim.nixosModules.nixvim

            ./hosts/effigy
            ./configuration.nix
            ./modules/terminal.nix
            ./modules/neovim.nix

            ./modules/desktop/niri.nix

            ./users/connor
          ];
        };

        opus = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs resources; };
          modules = [
            disko.nixosModules.disko
            sops-nix.nixosModules.sops

            stylix.nixosModules.stylix
            nixvim.nixosModules.nixvim

            nix-minecraft.nixosModules.minecraft-servers
            retrom.nixosModules.retrom

            ./hosts/opus
            ./configuration.nix
            ./modules/terminal.nix
            ./modules/neovim.nix

            ./modules/desktop/niri.nix

            ./users/connor
            ./users/kendrick
            ./users/liam
          ];
        };

        cadence = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            disko.nixosModules.disko
            sops-nix.nixosModules.sops

            nixvim.nixosModules.nixvim
            stylix.nixosModules.stylix

            ./hosts/cadence
            ./configuration.nix
            ./modules/terminal.nix
            ./modules/neovim.nix

            ./users/connor
          ];
        };

        insomnia = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            disko.nixosModules.disko
            sops-nix.nixosModules.sops

            stylix.nixosModules.stylix
            nixvim.nixosModules.nixvim

            ./hosts/insomnia
            ./configuration.nix
            ./modules/terminal.nix
            ./modules/neovim.nix

            ./users/connor
          ];
        };
      };
    };
}
