{ config, ... }:
let
  cfg = config.users.users.connor;
in
{
  sops.secrets = {
    "connor/passwd" = {
      sopsFile = ./secrets.yaml;
      neededForUsers = true;
    };
    "connor/age" = {
      sopsFile = ./secrets.yaml;
      path = "${cfg.home}/.config/sops/age/keys.txt";
      owner = cfg.name;
      group = cfg.group;
    };
  };
}
