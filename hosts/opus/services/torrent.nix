{ config, ... }:
let
  secrets = config.sops.secrets;
  hosts = {
    localhost = "localhost:${toString config.services.qbittorrent.webuiPort}";
  };
in
{
  sops.secrets = {
    "wg.conf" = {
      sopsFile = secrets/wg.conf;
      format = "binary";
    };
  };

  services.qbittorrent = {
    enable = true;
    webuiPort = 7736;
    torrentingPort = 7737;
  };

  services.nginx.upstreams.qbittorrent.servers.${hosts.localhost} = { };
  services.nginx.virtualHosts."torrent.home.arpa" = {
    addSSL = true;
    enableACME = true;
    locations."/".proxyPass = "http://qbittorrent";
  };

  networking.wg-quick.interfaces.wg0 = {
    configFile = secrets."wg.conf".path;
  };

  networking.firewall.allowedUDPPorts = [ config.services.qbittorrent.torrentingPort ];
  networking.firewall.allowedTCPPorts = [ config.services.qbittorrent.torrentingPort ];
}
