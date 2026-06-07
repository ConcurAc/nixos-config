{ config, lib, ... }:
let
  secrets = config.sops.secrets;
  hosts = {
    localhost = "localhost:${toString config.services.tandoor-recipes.port}";
  };
in
{
  sops.secrets."tandoor.env" = lib.mkIf config.services.tandoor-recipes.enable {
    sopsFile = secrets/tandoor.env;
    key = "";
    format = "dotenv";
    owner = config.services.tandoor-recipes.user;
    group = config.services.tandoor-recipes.group;
  };
  services.tandoor-recipes = {
    enable = true;
    database.createLocally = true;
    extraConfig = {
      MEDIA_ROOT = "/var/lib/tandoor-recipes/media";
      ALLOWED_HOSTS = "recipes.home.arpa";
    };
  };
  systemd.services = {
    tandoor-recipes = lib.mkIf config.services.tandoor-recipes.enable {
      serviceConfig.EnvironmentFile = secrets."tandoor.env".path;
    };
  };
  services.nginx.upstreams.tandoor.servers.${hosts.localhost} = { };
  services.nginx.virtualHosts."recipes.home.arpa" = {
    addSSL = true;
    enableACME = true;
    locations."/".proxyPass = "http://tandoor";
  };
}
