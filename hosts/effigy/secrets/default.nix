let
  prefix = "hosts/effigy";
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
  mod = {
    sops.secrets = builtins.listToAttrs [
      (set {
        key = "passwd";
        options = {
          sopsFile = ./secrets.yaml;
          neededForUsers = true;
        };
      })
      (set {
        key = "wg-home";
        options = {
          sopsFile = ./wg-home.conf;
          format = "binary";
        };
      })
      (set {
        key = "wg-proxy";
        options = {
          sopsFile = ./wg-proxy.conf;
          format = "binary";
        };
      })
    ];
  };
}
