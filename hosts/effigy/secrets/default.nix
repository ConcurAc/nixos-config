{
  sops.secrets = {
    "passwd" = {
      sopsFile = ./secrets.yaml;
      neededForUsers = true;
    };
    "wg-home" = {
      sopsFile = ./wg-home.conf;
      format = "binary";
    };
    "wg-proxy" = {
      sopsFile = ./wg-proxy.conf;
      format = "binary";
    };
  };
}
