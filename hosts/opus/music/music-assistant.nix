{ config, ... }:
let
  inherit (config.sops) secrets;
  hosts = {
    localhost = "localhost:8095";
  };
in
{
  sops.secrets."music-assistant.env" = {
    sopsFile = ./secrets/music-assistant.env;
    key = "";
    format = "dotenv";
    mode = "0666";
  };

  services.music-assistant = {
    enable = true;
    openFirewall = true;
    providers = [
      "soundcloud"
      "spotify"
      "ytmusic"

      "musicbrainz"
    ];
  };

  systemd.services.music-assistant = {
    serviceConfig.EnvironmentFile = secrets."music-assistant.env".path;
  };

  networking.firewall.allowedTCPPorts = [ 8095 ];

  services.nginx = {
    upstreams.music-assistant.servers.${hosts.localhost} = { };
    virtualHosts."music.home.arpa" = {
      addSSL = true;
      enableACME = true;
      locations = {
        "/" = {
          proxyPass = "http://music-assistant";
          proxyWebsockets = true;
        };
        "/ws" = {
          proxyPass = "http://music-assistant";
          proxyWebsockets = true;
        };
      };
    };
  };
}
