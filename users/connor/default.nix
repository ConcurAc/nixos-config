{
  assets,
  modules,
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.users.users.connor;
  secrets = config.sops.secrets;
in
{
  imports = with modules; [
    features
    users.containers

    ./secrets
  ];

  users = {
    users.connor = {
      isNormalUser = true;
      uid = 1000;
      home = "/home/connor";
      hashedPasswordFile = secrets."connor/passwd".path;
      extraGroups = [
        "wheel"
        "networkmanager"
        "libvirtd"
        "wireshark"

        "games"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINkxIAco0SzBIb8nGCL3QerUP7hp/kzv1gkHbmtoBVMp"
      ];
      shell = pkgs.fish;
    };

    containers.users.connor = {
      enable = false;
      withGpu = true;

      config = {
        _module.args = { inherit assets; };

        imports = with inputs; [
          sops-nix.nixosModules.sops
          stylix.nixosModules.stylix

          modules.defaults

          ./container
        ];

        sops.age.keyFile = secrets."connor/age".path;

        stylix = {
          enable = true;
          base16Scheme = assets.palette.hephae-soft;
        };

        programs.fish.enable = true;
      };

      overrides = {
        bindMounts = {
          ${secrets."connor/age".path}.hostPath = secrets."connor/age".path;
          "/srv/users/${cfg.name}".hostPath = "/srv/users/${cfg.name}";
        };
      };
    };
  };

  features = {
    development = {
      enable = lib.mkDefault true;
      nix = lib.mkDefault true;
    };
    gaming = {
      enable = lib.mkDefault true;
    };
  };

  programs = {
    niri.enable = true;
  };

  environment.systemPackages = with pkgs; [
    xwayland-satellite
  ];
}
