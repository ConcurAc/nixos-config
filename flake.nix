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
  };

  outputs =
    inputs@{
      nixpkgs,
      disko,
      sops-nix,
      ...
    }:
    {
      nixosConfigurations.effigy = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ./hosts/effigy
          ./configuration.nix
          ./modules/terminal.nix

          ./modules/desktop/hyprland.nix
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
          ./hosts/hub
          ./configuration.nix
          ./modules/terminal.nix

          ./modules/desktop/sway.nix
          ./modules/desktop/hyprland.nix
          ./modules/desktop/niri.nix

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
