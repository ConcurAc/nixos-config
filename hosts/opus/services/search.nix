{ config, lib, ... }:
let
  secrets = config.sops.secrets;
in
{
  sops.secrets."searx.env" = lib.mkIf config.services.searx.enable {
    sopsFile = ./secrets/searx.env;
    key = "";
    format = "dotenv";
    owner = "searx";
    group = "searx";
  };

  services.searx = {
    enable = true;
    environmentFile = secrets."searx.env".path;

    configureNginx = true;
    redisCreateLocally = true;

    domain = "search.home.arpa";

    uwsgiConfig = {
      disable-logging = true;
    };
    faviconsSettings = {
      favicons = {
        cfg_schema = 1;
        cache = {
          db_url = "/var/cache/searx/faviconcache.db";
          HOLD_TIME = 7 * 24 * 60 * 60; # cache for a week
          LIMIT_TOTAL_BYTES = 268435456;
          BLOB_MAX_BYTES = 40960;
          MAINTENANCE_MODE = "auto";
          MAINTENANCE_PERIOD = 600;
        };
      };
    };

    settings = {
      server = {
        secret_key = "$SEARX_SECRET_KEY";
      };
      search = {
        formats = [
          "html"
          "json"
        ];

        max_results = 5;
        timeout = 2;

        cache = lib.mkIf config.services.searx.redisCreateLocally {
          enabled = true;
          type = "redis";
          ttl = 7 * 24 * 60 * 60; # cache for a week
          url = "unix://${config.services.redis.servers.searx.unixSocket}";
        };
      };
    };
  };

  services.nginx.virtualHosts.${config.services.searx.domain} = {
    addSSL = true;
    enableACME = true;
  };
}
