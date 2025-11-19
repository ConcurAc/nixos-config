{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
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
    quickshell = {
      url = "github:outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia-shell = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        quickshell.follows = "quickshell";
      };
    };
    retrom = {
      url = "github:concurac/retrom/nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      sops-nix,
      disko,
      home-manager,
      stylix,
      nixvim,
      noctalia-shell,
      retrom,
      ...
    }:
    {
      nixosConfigurations = {
        effigy = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            disko.nixosModules.disko
            sops-nix.nixosModules.sops

            stylix.nixosModules.stylix
            nixvim.nixosModules.nixvim

            retrom.nixosModules.retrom

            ./hosts/effigy
            ./configuration.nix
            ./modules/terminal.nix
            ./modules/neovim.nix

            ./modules/desktop/niri.nix

            ./users/connor
          ];
        };

        hub = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            disko.nixosModules.disko
            sops-nix.nixosModules.sops

            stylix.nixosModules.stylix
            nixvim.nixosModules.nixvim

            noctalia-shell.nixosModules.default
            retrom.nixosModules.retrom

            ./hosts/hub
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

            stylix.nixosModules.stylix

            ./hosts/cadence
            ./configuration.nix
            ./modules/terminal.nix

            ./users/connor
          ];
        };
      };
    };
}
