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
  secrets = import ./secrets;
in
{
  imports = with modules; [
    features
    user-containers

    secrets.mod
  ];

  users.users.connor = {
    isNormalUser = true;
    uid = 1000;
    home = "/home/connor";
    hashedPasswordFile = secrets.get config "passwd";
    extraGroups = [
      "wheel"
      "networkmanager"
      "libvirtd"
      "wireshark"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINkxIAco0SzBIb8nGCL3QerUP7hp/kzv1gkHbmtoBVMp"
    ];
    shell = pkgs.fish;
  };

  features = {
    development = {
      enable = lib.mkDefault true;
    };
    gaming = {
      enable = lib.mkDefault true;
    };
  };

  programs = {
    niri.enable = true;
    xwayland.enable = true;
  };

  user-containers.users.connor = {
    enable = true;
    bindMounts = {
      ${config.sops.age.keyFile}.hostPath = config.sops.age.keyFile;
      "/home/data".hostPath = "/srv/users/${cfg.name}";
    };
    config = {
      imports =
        with inputs;
        [
          sops-nix.nixosModules.sops
          stylix.nixosModules.stylix
        ]
        ++ [
          ../../modules/terminal.nix
          ./container
        ];
      sops.age.keyFile = config.sops.age.keyFile;
      stylix = {
        enable = true;
        base16Scheme = "${pkgs.base16-schemes}/share/themes/brewer.yaml";
      };
    };
  };
}
