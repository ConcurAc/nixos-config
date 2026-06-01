{ lib, ... }:
let
  get =
    {
      key,
      options,
    }:
    lib.nameValuePair "hosts/effigy/${key}" (
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
      key = "wg-home";
      options = {
        sopsFile = ./wg-home.conf;
        format = "binary";
      };
    })
    (get {
      key = "wg-proxy";
      options = {
        sopsFile = ./wg-proxy.conf;
        format = "binary";
      };
    })
  ];
}
