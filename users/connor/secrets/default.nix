let
  prefix = "users/connor";
  get = config: key: config.sops.secrets."${prefix}/${key}".path;
  set =
    {
      key,
      options,
    }:
    {
      name = "${prefix}/${key}";
      value = {
        inherit key;
      }
      // options;
    };
in
{
  inherit get;
  mod =
    { config, ... }:
    let
      cfg = config.users.users.connor;
    in
    {
      sops.secrets = builtins.listToAttrs [
        (set {
          key = "passwd";
          options = {
            sopsFile = ./secrets.yaml;
            neededForUsers = true;
          };
        })
        (set {
          key = "age";
          options = {
            sopsFile = ./secrets.yaml;
            path = "${cfg.home}/.config/sops/age/keys.txt";
            owner = cfg.name;
            group = cfg.group;
          };
        })
      ];
    };
}
