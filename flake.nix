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
      ...
    }:
    {
      nixosConfigurations.effigy = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          home-manager.nixosModules.default
          stylix.nixosModules.stylix
          nixvim.nixosModules.nixvim
          noctalia-shell.nixosModules.default

          ./hosts/effigy
          ./configuration.nix

          ./modules/desktop/niri.nix

          ./users/connor
        ];
      };

      nixosConfigurations.hub = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          stylix.nixosModules.stylix

          noctalia-shell.nixosModules.default
          ./hosts/hub
          ./configuration.nix
          ./modules/terminal.nix

          ./modules/desktop/niri.nix
          ./modules/desktop/gnome.nix

          ./users/connor
          ./users/kendrick
          ./users/liam
        ];
      };

      nixosConfigurations.cadence = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ./hosts/cadence
          ./configuration.nix
        ];
      };
    };
}
