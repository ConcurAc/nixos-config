{ lib, ... }:
let
  get =
    {
      key,
      options,
    }:
    lib.nameValuePair "hosts/opus/${key}" (
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
  ];
}
