{
  inputs,
  config,
  pkgs,
  ...
}:
let
  cfg = config.users.users.connor;
in
{
  imports = with inputs; [
    sops-nix.nixosModules.sops
  ];

  sops.secrets.connor-passwd = {
    sopsFile = ./secrets.yaml;
    neededForUsers = true;
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
    ];
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
  ];
}
