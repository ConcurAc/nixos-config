{ config, ... }:
let
  hosts = {
    localhost = "localhost:${toString config.services.trilium-server.port}";
  };
in
{
  services.trilium-server = {
    enable = true;
    instanceName = "Connor's Notes";
  };

  services.nginx = {
    upstreams.trilium.servers.${hosts.localhost} = { };
    virtualHosts."notes.connor.home.arpa" = {
      addSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://trilium";
        proxyWebsockets = true;
      };
      extraConfig = ''
        client_max_body_size 0;
      '';
    };
  };
}
