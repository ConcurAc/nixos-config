{
  inputs,
  config,
  pkgs,
  ...
}:
let
  cfg = config.users.users.connor;
  userKeyFile = "${cfg.home}/.config/sops/age/keys.txt";
in
{
  imports =
    with inputs;
    [
      sops-nix.nixosModules.sops
    ]
    ++ [
      ../../modules/user-containers.nix
    ];

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
    packages = with pkgs; [
      home-manager
      brave
    ];
  };

  user-containers.users.connor = {
    enable = true;
    withMacvlan = true;
    bindMounts = {
      ${userKeyFile}.hostPath = config.sops.age.keyFile;
    };
    config = {
      imports =
        with inputs;
        [
          sops-nix.nixosModules.sops
          nixvim.nixosModules.nixvim
        ]
        ++ [
          ../../modules/terminal.nix
          ./container.nix
        ];
      sops.age.keyFile = userKeyFile;
    };
  };

  programs.fuse.userAllowOther = true;

  security.pam.mount.extraVolumes = [
    # CAN SOMEONE ACCEPT MY PR SO I CAN GET RID OF THIS
    # https://github.com/NixOS/nixpkgs/pull/453507
    ''<path>/run/wrappers/bin:${pkgs.util-linux}/bin:${pkgs.gocryptfs}/bin</path>''
    ''
      <volume
        user="${cfg.name}"
        mountpoint="${cfg.home}/Media"
        path="gocryptfs#${cfg.home}/.crypt/media"
        fstype="fuse"
      />
    ''
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
        mountpoint="/mnt/users/${cfg.name}/archives"
        path="gocryptfs#/mnt/users/${cfg.name}/.crypt/@archives"
        fstype="fuse"
      />
    ''
  ];
}
