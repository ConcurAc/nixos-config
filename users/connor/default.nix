{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.users.users.connor;
  cfgContainer = config.container-services.users.connor;
  userKeyFile = "${cfg.home}/.config/sops/age/keys.txt";
in
{
  imports = [
    ../../modules/user-containers.nix
  ]
  ++ (with inputs; [
    sops-nix.nixosModules.sops
  ]);

  sops.secrets = {
    connor-passwd = {
      sopsFile = ./secrets.yaml;
      neededForUsers = true;
    };
  };

  users.users.connor = {
    isNormalUser = true;
    uid = 1000;
    home = "/home/connor";
    hashedPasswordFile = config.sops.secrets.connor-passwd.path;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII2mcsUw0CZ5ktg3c6FG91OGfO8mGCKImZ1aLOmdwl5a"
    ];
    shell = pkgs.fish;
    linger = true;
    packages = with pkgs; [
      home-manager
      brave
    ];
  };

  user-containers.users.connor = {
    container = {
      enable = true;
      withMacvlan = true;
      bindMounts = {
        ${userKeyFile}.hostPath = config.sops.age.keyFile;
        "/mnt/gallery" = {
          hostPath = "$/mnt/users/${cfg.name}/gallery";
          isReadOnly = false;
        };
      };
      config = {
        imports = [
          inputs.sops-nix.nixosModules.sops
          ../../modules/terminal.nix
          ./container.nix
        ];
        sops.age.keyFile = userKeyFile;
      };
    };
  };

  security.pam.mount.extraVolumes = [
    ''
      <volume
        user="${cfg.name}"
        mountpoint="${cfg.home}/Media"
        path="gocryptfs#${cfg.home}/.crypt/media"
        fstype="fuse"
      />
    ''
  ]
  ++ lib.mkIf (config.container-services.enable && cfgContainer.enable) [
    ''
      <volume
        user="${cfg.name}"
        mountpoint="/mnt/users/${cfg.name}/media"
        path="gocryptfs#/mnt/users/${cfg.name}/.crypt/@media"
        fstype="fuse"
      />
    ''
    ''
      <volume
        user="${cfg.name}"
        mountpoint="/mnt/users/${cfg.name}/music"
        path="gocryptfs#/mnt/users/${cfg.name}/.crypt/@music"
        fstype="fuse"
      />
    ''
    ''
      <volume
        user="${cfg.name}"
        mountpoint="/mnt/users/${cfg.name}/gallery"
        path="gocryptfs#/mnt/users/${cfg.name}/.crypt/@gallery"
        fstype="fuse"
      />
    ''
  ];
}
