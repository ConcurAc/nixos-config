{ config, ... }:
let
  secrets = config.sops.secrets;
  hosts = {
    localhost = "localhost:${toString config.services.immich-kiosk.settings.kiosk.port}";
  };
in
{
  sops.secrets = {
    "immich/api-keys/connor" = {
      sopsFile = secrets/immich.yaml;
    };
    "immich/api-keys/arete" = {
      sopsFile = secrets/immich.yaml;
    };
  };

  services.immich-kiosk = {
    enable = true;
    settings = {
      kiosk.port = 3030;
      immich_url = "https://photos.home.arpa";
      immich_api_key._secret = secrets."immich/api-keys/arete".path;
      immich_users_api_keys = {
        arete._secret = secrets."immich/api-keys/arete".path;
      };
      show_videos = true;
      live_photos = true;
    };
  };

  services.nginx.upstreams.immich-kiosk.servers.${hosts.localhost} = { };
  services.nginx.virtualHosts."kiosk.home.arpa" = {
    addSSL = true;
    enableACME = true;
    locations."/".proxyPass = "http://immich-kiosk";
  };
}
