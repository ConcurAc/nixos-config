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
    shell = pkgs.fish;
  };
}
