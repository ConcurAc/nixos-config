{ config, ... }:
let
  secrets = config.sops.secrets;
  hosts = {
    localhost = "localhost:${toString config.services.retrom.port}";
  };
in
{
  sops.secrets = {
    "retrom.json" = {
      sopsFile = secrets/retrom.json;
      key = "";
      format = "json";
      owner = config.services.retrom.user;
      group = config.services.retrom.group;
    };
  };

  services.retrom = {
    enable = true;
    enableDatabase = true;
    configFile = secrets."retrom.json".path;
  };

  services.nginx.upstreams.retrom.servers.${hosts.localhost} = { };
  services.nginx.virtualHosts."games.home.arpa" = {
    addSSL = true;
    enableACME = true;
    locations."/".proxyPass = "http://retrom";
  };
}
