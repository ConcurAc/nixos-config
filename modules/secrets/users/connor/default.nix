{ config, lib, ... }:
let
  cfg = config.users.users.connor;
  get =
    {
      key,
      options,
    }:
    lib.nameValuePair "users/connor/${key}" (
      {
        inherit key;
      }
      // options
    );
in
{
  sops.secrets = builtins.listToAttrs [
    (get {
      key = "passwd";
      options = {
        sopsFile = ./secrets.yaml;
        neededForUsers = true;
      };
    })
    (get {
      key = "age";
      options = {
        sopsFile = ./secrets.yaml;
        path = "${cfg.home}/.config/sops/age/keys.txt";
        owner = cfg.name;
        group = cfg.group;
      };
    })
  ];
}
