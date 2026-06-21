{
  inputs,
  modules,
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
    user-containers

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
        "linux_users"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINkxIAco0SzBIb8nGCL3QerUP7hp/kzv1gkHbmtoBVMp"
      ];
      shell = pkgs.fish;
    };

    containers.users.connor = {
      enable = false;
      bindMounts = {
        ${config.sops.age.keyFile}.hostPath = config.sops.age.keyFile;
        "/home/data".hostPath = "/srv/users/${cfg.name}";
      };
      config = {
        imports = with inputs; [
          sops-nix.nixosModules.sops
          stylix.nixosModules.stylix

          ./container
        ];
        sops.age.keyFile = config.sops.age.keyFile;
        stylix = {
          enable = true;
          base16Scheme = "${pkgs.base16-schemes}/share/themes/brewer.yaml";
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

  environment.systemPackages = with pkgs; [
    xwayland-satellite
  ];

  programs = {
    niri.enable = true;

  };
}
