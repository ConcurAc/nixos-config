{ config, ... }:
let
  hosts = {
    localhost = "localhost:${toString config.services.immich.port}";
  };
in
{
  services.immich = {
    enable = true;
    accelerationDevices = [
      "/dev/dri/renderD128"
    ];
  };
  services.nginx.upstreams.immich.servers.${hosts.localhost} = { };
  services.nginx.virtualHosts."photos.home.arpa" = {
    addSSL = true;
    enableACME = true;
    locations."/".proxyPass = "http://immich";
    extraConfig = ''
      client_max_body_size 512m;
    '';
  };
}
