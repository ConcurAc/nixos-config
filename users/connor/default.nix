{
  inputs,
  config,
  pkgs,
  ...
}:
{
  imports = with inputs; [
    sops-nix.nixosModules.sops
  ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "${config.users.users.connor.home}/.config/sops/age/keys.txt";
    secrets = {
      passwd.neededForUsers = true;
    };
  };

  users.users.connor = {
    isNormalUser = true;
    uid = 1000;
    home = "/home/connor";
    hashedPasswordFile = config.sops.secrets.passwd.path;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII2mcsUw0CZ5ktg3c6FG91OGfO8mGCKImZ1aLOmdwl5a"
    ];
    shell = pkgs.fish;
  };
}
